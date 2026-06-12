from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('services', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='servicerequest',
            name='current_status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('on_hold', 'On Hold'),
                    ('accepted', 'Accepted'),
                    ('in_progress', 'In Progress'),
                    ('completed', 'Completed'),
                    ('cancelled', 'Cancelled'),
                ],
                db_index=True,
                default='pending',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='servicerequeststatustracking',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('on_hold', 'On Hold'),
                    ('accepted', 'Accepted'),
                    ('in_progress', 'In Progress'),
                    ('completed', 'Completed'),
                    ('cancelled', 'Cancelled'),
                ],
                max_length=20,
            ),
        ),
    ]
