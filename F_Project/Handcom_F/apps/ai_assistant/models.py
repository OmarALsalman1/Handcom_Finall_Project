from django.db import models


class AIAssistant(models.Model):
    """Singleton-like entity representing the Handcom AI assistant."""
    ai_id = models.AutoField(primary_key=True)
    ai_name = models.CharField(max_length=100)
    purpose = models.CharField(max_length=255, blank=True, null=True)
    activation_date = models.DateField(auto_now_add=True)

    class Meta:
        db_table = 'ai_assistant'

    def __str__(self):
        return self.ai_name


class AIConversation(models.Model):
    """A single AI-assisted problem-solving session for a Service User."""
    ai_conversation_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(
        'accounts.User', on_delete=models.CASCADE, related_name='ai_conversations'
    )
    ai = models.ForeignKey(AIAssistant, on_delete=models.PROTECT)
    started_at = models.DateTimeField(auto_now_add=True)
    last_analysis = models.JSONField(null=True, blank=True)

    class Meta:
        db_table = 'ai_conversation'
        ordering = ['-started_at']

    def __str__(self):
        return f"AI Conversation #{self.ai_conversation_id} ({self.user})"


class AIMessage(models.Model):
    SENDER = [('user', 'User'), ('ai', 'AI')]
    INPUT_TYPE = [('text', 'Text'), ('image', 'Image'), ('voice', 'Voice')]

    ai_message_id = models.AutoField(primary_key=True)
    conversation = models.ForeignKey(
        AIConversation, on_delete=models.CASCADE, related_name='messages'
    )
    sender = models.CharField(max_length=10, choices=SENDER)
    input_type = models.CharField(max_length=10, choices=INPUT_TYPE, default='text')
    content = models.TextField(blank=True)
    media_url = models.URLField(blank=True, null=True)
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'ai_message'
        ordering = ['sent_at']

    def __str__(self):
        return f"[{self.sender}] {self.content[:50]}"
