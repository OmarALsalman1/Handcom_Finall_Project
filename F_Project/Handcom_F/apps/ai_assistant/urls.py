from django.urls import path
from . import views

urlpatterns = [
    path('ai/chat/', views.AIChatView.as_view(), name='ai-chat'),
    path('ai/create-request/', views.AICreateRequestView.as_view(), name='ai-create-request'),
    path('ai/conversations/', views.AIConversationListView.as_view(), name='ai-conversation-list'),
    path('ai/conversations/<int:pk>/', views.AIConversationDetailView.as_view(), name='ai-conversation-detail'),
]
