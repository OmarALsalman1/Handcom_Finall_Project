from django.contrib import admin
from .models import Conversation, Message


class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    readonly_fields = ('sender_type', 'content', 'sent_at')
    can_delete = False


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('conversation_id', 'user', 'service_provider', 'conversation_status', 'started_at')
    list_filter = ('conversation_status',)
    search_fields = ('user__email', 'service_provider__email')
    inlines = [MessageInline]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('message_id', 'conversation', 'sender_type', 'sent_at')
    list_filter = ('sender_type',)
