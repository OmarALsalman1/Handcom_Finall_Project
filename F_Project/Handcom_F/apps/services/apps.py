from django.apps import AppConfig


class ServicesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.services'
    label = 'services'

    def ready(self):
        import apps.services.signals  # noqa: F401
