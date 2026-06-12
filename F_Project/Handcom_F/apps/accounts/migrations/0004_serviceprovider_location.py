from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0003_serviceprovider_bio_serviceprovider_services_offered'),
    ]

    operations = [
        migrations.AddField(
            model_name='serviceprovider',
            name='latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='serviceprovider',
            name='longitude',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
