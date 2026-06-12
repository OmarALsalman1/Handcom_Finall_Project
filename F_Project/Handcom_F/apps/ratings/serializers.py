from rest_framework import serializers
from .models import Rating


class RatingCreateSerializer(serializers.Serializer):
    service_id = serializers.IntegerField()
    rating_value = serializers.IntegerField(min_value=1, max_value=5)
    rating_comment = serializers.CharField(required=False, allow_blank=True, default='')


class RatingSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()

    class Meta:
        model = Rating
        fields = ('rating_id', 'user_name', 'rating_value', 'rating_comment', 'rating_date')

    def get_user_name(self, obj):
        return obj.user.full_name
