from django.contrib import admin
from .models import ServiceProviderSchedule


@admin.register(ServiceProviderSchedule)
class ServiceProviderScheduleAdmin(admin.ModelAdmin):
    list_display = (
        'service_provider_schedule_id', 'service_provider',
        'working_date', 'start_time', 'end_time',
    )
    list_filter = ('working_date',)
    search_fields = ('service_provider__email', 'service_provider__full_name')
    ordering = ('working_date', 'start_time')
