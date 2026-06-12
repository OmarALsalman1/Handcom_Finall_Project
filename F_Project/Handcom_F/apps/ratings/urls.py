from django.urls import path
from . import views

urlpatterns = [
    path('ratings/', views.RatingCreateView.as_view(), name='rating-create'),
    path('service-providers/<int:pk>/ratings/', views.ServiceProviderRatingsListView.as_view(), name='provider-ratings'),
    path('service-providers/<int:pk>/ratings/summary/', views.ServiceProviderRatingsSummaryView.as_view(), name='provider-ratings-summary'),
]
