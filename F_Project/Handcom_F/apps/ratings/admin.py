from django.contrib import admin
from .models import Rating


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ('rating_id', 'user', 'service_provider', 'rating_value', 'rating_date')
    list_filter = ('rating_value',)
    search_fields = ('user__email', 'service_provider__email')
    readonly_fields = ('rating_date',)
