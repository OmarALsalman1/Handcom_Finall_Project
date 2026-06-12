from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.accounts.models import User, ServiceProvider
from apps.services.models import Service


class Rating(models.Model):
    rating_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='given_ratings')
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.CASCADE, related_name='received_ratings'
    )
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name='ratings')
    service_category = models.CharField(max_length=100, blank=True, default='')
    rating_value = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    rating_comment = models.TextField(blank=True, null=True)
    rating_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'rating'
        unique_together = ('user', 'service')

    def __str__(self):
        return f"{self.user} rated {self.service_provider}: {self.rating_value}/5"
