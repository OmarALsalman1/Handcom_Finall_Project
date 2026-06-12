from django.contrib import admin
from .models import ServiceRequest, Service, ServiceRequestStatusTracking, SavedProvider


class StatusTrackingInline(admin.TabularInline):
    model = ServiceRequestStatusTracking
    extra = 0
    readonly_fields = ('status', 'status_date')
    can_delete = False


@admin.register(ServiceRequest)
class ServiceRequestAdmin(admin.ModelAdmin):
    list_display = ('service_request_id', 'user', 'service_type', 'current_status', 'service_provider', 'created_at')
    list_filter = ('current_status', 'service_type')
    search_fields = ('user__email', 'service_type', 'location')
    inlines = [StatusTrackingInline]


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('service_id', 'service_name', 'service_provider', 'service_date')
    search_fields = ('service_name', 'service_provider__email')


@admin.register(ServiceRequestStatusTracking)
class StatusTrackingAdmin(admin.ModelAdmin):
    list_display = ('tracking_id', 'service_request', 'status', 'status_date')
    list_filter = ('status',)


@admin.register(SavedProvider)
class SavedProviderAdmin(admin.ModelAdmin):
    list_display = ('saved_id', 'user', 'service_provider', 'saved_at')
