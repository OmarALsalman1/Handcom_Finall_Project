from django.db import migrations


def backfill_service_category(apps, schema_editor):
    Rating = apps.get_model('ratings', 'Rating')
    for rating in Rating.objects.select_related('service__service_request').all():
        rating.service_category = rating.service.service_request.service_type
        rating.save(update_fields=['service_category'])


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('ratings', '0002_rating_service_category'),
    ]

    operations = [
        migrations.RunPython(backfill_service_category, noop_reverse),
    ]
