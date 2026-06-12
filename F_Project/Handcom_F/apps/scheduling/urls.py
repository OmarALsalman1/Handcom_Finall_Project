from django.urls import path
from . import views

urlpatterns = [
    # SP-authenticated schedule management
    path('schedules/', views.ScheduleCreateView.as_view(), name='schedule-create'),
    path('schedules/me/', views.MyScheduleListView.as_view(), name='schedule-me'),
    path('schedules/<int:pk>/', views.ScheduleDetailView.as_view(), name='schedule-detail'),

    # Public: provider's upcoming schedule
    path('service-providers/<int:pk>/schedule/', views.ServiceProviderPublicScheduleView.as_view(), name='provider-schedule'),
]
