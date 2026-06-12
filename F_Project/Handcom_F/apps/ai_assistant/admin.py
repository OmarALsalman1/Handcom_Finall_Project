from django.contrib import admin
from .models import AIAssistant, AIConversation, AIMessage


class AIMessageInline(admin.TabularInline):
    model = AIMessage
    extra = 0
    readonly_fields = ('sender', 'input_type', 'content', 'sent_at')
    can_delete = False


@admin.register(AIAssistant)
class AIAssistantAdmin(admin.ModelAdmin):
    list_display = ('ai_id', 'ai_name', 'purpose', 'activation_date')


@admin.register(AIConversation)
class AIConversationAdmin(admin.ModelAdmin):
    list_display = ('ai_conversation_id', 'user', 'started_at')
    search_fields = ('user__email',)
    inlines = [AIMessageInline]


@admin.register(AIMessage)
class AIMessageAdmin(admin.ModelAdmin):
    list_display = ('ai_message_id', 'conversation', 'sender', 'input_type', 'sent_at')
    list_filter = ('sender', 'input_type')
