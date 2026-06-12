from django.urls import path
from . import views

urlpatterns = [
    # ── Service Requests ──────────────────────────────────────────────────────
    path('service-requests/', views.ServiceRequestListCreateView.as_view(), name='service-request-list'),
    path('service-requests/<int:pk>/', views.ServiceRequestDetailView.as_view(), name='service-request-detail'),
    path('service-requests/<int:pk>/cancel/', views.ServiceRequestCancelView.as_view(), name='service-request-cancel'),
    path('service-requests/<int:pk>/assign/', views.ServiceRequestAssignView.as_view(), name='service-request-assign'),
    path('service-requests/<int:pk>/decline/', views.ServiceRequestDeclineView.as_view(), name='service-request-decline'),
    path('service-requests/<int:pk>/status/', views.ServiceRequestStatusUpdateView.as_view(), name='service-request-status'),
    path('service-requests/<int:pk>/tracking/', views.ServiceRequestTrackingView.as_view(), name='service-request-tracking'),

    # ── Services ──────────────────────────────────────────────────────────────
    path('services/', views.ServiceCreateView.as_view(), name='service-create'),
    path('services/<int:pk>/', views.ServiceDetailView.as_view(), name='service-detail'),

    # ── Saved Providers ───────────────────────────────────────────────────────
    path('saved-providers/', views.SavedProviderListView.as_view(), name='saved-provider-list'),
    path('saved-providers/add/', views.SavedProviderCreateView.as_view(), name='saved-provider-add'),
    path('saved-providers/<int:provider_id>/', views.SavedProviderDeleteView.as_view(), name='saved-provider-delete'),
]
