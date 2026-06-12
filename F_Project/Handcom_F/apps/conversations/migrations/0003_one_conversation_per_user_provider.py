import django.db.models.deletion
from django.db import migrations, models


def merge_duplicate_conversations(apps, schema_editor):
    Conversation = apps.get_model('conversations', 'Conversation')
    Message = apps.get_model('conversations', 'Message')

    seen = set()
    for conv in Conversation.objects.order_by('started_at'):
        key = (conv.user_id, conv.service_provider_id)
        if key in seen:
            continue
        seen.add(key)

        dupes = list(
            Conversation.objects
            .filter(user_id=conv.user_id, service_provider_id=conv.service_provider_id)
            .exclude(pk=conv.pk)
            .order_by('started_at')
        )
        if not dupes:
            continue

        keeper = conv
        group = [keeper] + dupes
        sr_ids = [c.service_request_id for c in group if c.service_request_id]
        if sr_ids:
            keeper.service_request_id = max(sr_ids)
        if any(c.conversation_status == 'open' for c in group):
            keeper.conversation_status = 'open'
        keeper.save()

        for dup in dupes:
            Message.objects.filter(conversation_id=dup.pk).update(conversation_id=keeper.pk)
            dup.delete()


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('conversations', '0002_alter_conversation_service_request'),
        ('services', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='conversation',
            name='service_request',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='conversations', to='services.servicerequest'),
        ),
        migrations.RunPython(merge_duplicate_conversations, noop_reverse),
        migrations.AddConstraint(
            model_name='conversation',
            constraint=models.UniqueConstraint(fields=('user', 'service_provider'), name='unique_conversation_per_user_provider'),
        ),
    ]
