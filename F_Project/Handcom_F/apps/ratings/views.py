from django.db.models import Avg, Count
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.accounts.models import ServiceProvider
from apps.accounts.permissions import IsServiceUser

from .models import Rating
from .serializers import RatingCreateSerializer, RatingSerializer
from .services import RatingService

_rating_service = RatingService()


@extend_schema(tags=['Ratings'], request=RatingCreateSerializer, responses={201: RatingSerializer})
class RatingCreateView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def post(self, request):
        serializer = RatingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        rating = _rating_service.submit_rating(
            user=request.user,
            service_id=d['service_id'],
            rating_value=d['rating_value'],
            rating_comment=d.get('rating_comment', ''),
        )
        return Response(RatingSerializer(rating).data, status=status.HTTP_201_CREATED)


@extend_schema(tags=['Ratings'], request=None, responses={200: RatingSerializer(many=True)})
class ServiceProviderRatingsListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        provider = get_object_or_404(ServiceProvider, pk=pk)
        ratings = Rating.objects.filter(
            service_provider=provider
        ).select_related('user').order_by('-rating_date')

        agg = ratings.aggregate(avg=Avg('rating_value'), total=Count('rating_id'))
        return Response({
            'average': round(agg['avg'], 2) if agg['avg'] else None,
            'total': agg['total'],
            'ratings': RatingSerializer(ratings, many=True).data,
        })


@extend_schema(tags=['Ratings'], request=None, responses={200: RatingSerializer})
class ServiceProviderRatingsSummaryView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        provider = get_object_or_404(ServiceProvider, pk=pk)
        ratings = Rating.objects.filter(service_provider=provider)

        agg = ratings.aggregate(avg=Avg('rating_value'), total=Count('rating_id'))
        distribution = {str(i): 0 for i in range(1, 6)}
        for row in ratings.values('rating_value').annotate(count=Count('rating_id')):
            distribution[str(row['rating_value'])] = row['count']

        return Response({
            'average': round(agg['avg'], 2) if agg['avg'] else None,
            'total': agg['total'],
            'distribution': distribution,
        })
