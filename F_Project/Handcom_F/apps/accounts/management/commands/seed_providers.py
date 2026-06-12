from django.core.management.base import BaseCommand
from apps.accounts.models import ServiceProvider

PROVIDERS = [
    {
        "full_name": "Ahmed Al-Rashidi",
        "email": "ahmed@provider.com",
        "password": "Test1234!",
        "phone": "0501234001",
        "experience_years": 8,
        "availability_status": "available",
        "service_categories": ["plumbing"],
        "bio": "Experienced plumber with 8 years in residential and commercial projects.",
        "services_offered": "Pipe repair, leak fixing, drain unblocking, water heater installation",
        "latitude": 31.9635, "longitude": 35.9306,
    },
    {
        "full_name": "Khalid Al-Mutairi",
        "email": "khalid@provider.com",
        "password": "Test1234!",
        "phone": "0501234002",
        "experience_years": 5,
        "availability_status": "available",
        "service_categories": ["electrical"],
        "bio": "Licensed electrician specializing in home wiring and safety inspections.",
        "services_offered": "Wiring, circuit breaker repair, electrical panel upgrade, lighting installation",
        "latitude": 31.9510, "longitude": 35.9250,
    },
    {
        "full_name": "Faisal Al-Harbi",
        "email": "faisal@provider.com",
        "password": "Test1234!",
        "phone": "0501234003",
        "experience_years": 10,
        "availability_status": "available",
        "service_categories": ["carpentry"],
        "bio": "Master carpenter with 10 years crafting custom furniture and woodwork.",
        "services_offered": "Furniture assembly, door installation, cabinet making, wooden flooring",
        "latitude": 31.9700, "longitude": 35.9150,
    },
    {
        "full_name": "Omar Al-Dossari",
        "email": "omar@provider.com",
        "password": "Test1234!",
        "phone": "0501234004",
        "experience_years": 4,
        "availability_status": "available",
        "service_categories": ["painting"],
        "bio": "Professional painter delivering high-quality interior and exterior finishes.",
        "services_offered": "Interior painting, exterior painting, wall texturing, wallpaper removal",
        "latitude": 31.9450, "longitude": 35.9400,
    },
    {
        "full_name": "Turki Al-Shamrani",
        "email": "turki@provider.com",
        "password": "Test1234!",
        "phone": "0501234005",
        "experience_years": 6,
        "availability_status": "available",
        "service_categories": ["electrical"],
        "bio": "Certified electrician specializing in home wiring, AC systems, and electrical maintenance.",
        "services_offered": "Wiring, socket installation, circuit breaker repair, AC electrical work",
        "latitude": 31.9580, "longitude": 35.9480,
    },
    {
        "full_name": "Nasser Al-Qahtani",
        "email": "nasser@provider.com",
        "password": "Test1234!",
        "phone": "0501234006",
        "experience_years": 3,
        "availability_status": "available",
        "service_categories": ["painting"],
        "bio": "Reliable painter specializing in interior and exterior wall finishes.",
        "services_offered": "Interior painting, exterior painting, wall priming, decorative finishes",
        "latitude": 31.9390, "longitude": 35.9050,
    },
    {
        "full_name": "Saad Al-Ghamdi",
        "email": "saad@provider.com",
        "password": "Test1234!",
        "phone": "0501234007",
        "experience_years": 7,
        "availability_status": "busy",
        "service_categories": ["plumbing", "carpentry"],
        "bio": "Multi-skilled technician covering plumbing and carpentry.",
        "services_offered": "Leak repair, toilet installation, door fitting, wooden fixture repair",
        "latitude": 31.9760, "longitude": 35.9350,
    },
    {
        "full_name": "Walid Al-Zahrani",
        "email": "walid@provider.com",
        "password": "Test1234!",
        "phone": "0501234008",
        "experience_years": 9,
        "availability_status": "available",
        "service_categories": ["electrical", "carpentry"],
        "bio": "Versatile technician offering both electrical work and carpentry.",
        "services_offered": "Smart home wiring, shelving, kitchen cabinet fitting, pendant lighting",
        "latitude": 31.9320, "longitude": 35.9200,
    },
    {
        "full_name": "Ibrahim Al-Otaibi",
        "email": "ibrahim@provider.com",
        "password": "Test1234!",
        "phone": "0501234009",
        "experience_years": 2,
        "availability_status": "available",
        "service_categories": ["painting"],
        "bio": "Fresh and detail-oriented painter focused on quality finishes.",
        "services_offered": "Room painting, touch-ups, exterior walls, decorative painting",
        "latitude": 31.9830, "longitude": 35.9100,
    },
    {
        "full_name": "Majid Al-Shehri",
        "email": "majid@provider.com",
        "password": "Test1234!",
        "phone": "0501234010",
        "experience_years": 12,
        "availability_status": "available",
        "service_categories": ["plumbing", "electrical"],
        "bio": "Senior multi-trade professional with over a decade of experience.",
        "services_offered": "Full home maintenance, water system checks, electrical safety inspections, pipe repair",
        "latitude": 31.9480, "longitude": 35.8980,
    },
    {
        "full_name": "Bandar Al-Anzi",
        "email": "bandar@provider.com",
        "password": "Test1234!",
        "phone": "0501234011",
        "experience_years": 5,
        "availability_status": "available",
        "service_categories": ["carpentry"],
        "bio": "Skilled carpenter specializing in doors, windows, and built-in furniture.",
        "services_offered": "Door repair, window frames, built-in wardrobes, wooden partitions",
        "latitude": 31.9610, "longitude": 35.9550,
    },
    {
        "full_name": "Rayan Al-Subaie",
        "email": "rayan@provider.com",
        "password": "Test1234!",
        "phone": "0501234012",
        "experience_years": 3,
        "availability_status": "available",
        "service_categories": ["carpentry"],
        "bio": "Skilled carpenter focused on furniture repair, doors, and wooden fixtures.",
        "services_offered": "Door repair, drawer fixing, shelf installation, furniture assembly",
        "latitude": 31.9420, "longitude": 35.9600,
    },
    {
        "full_name": "Hani Al-Bishi",
        "email": "hani@provider.com",
        "password": "Test1234!",
        "phone": "0501234013",
        "experience_years": 6,
        "availability_status": "available",
        "service_categories": ["electrical"],
        "bio": "Skilled electrician handling home electrical systems and installations.",
        "services_offered": "Socket installation, lighting setup, generator wiring, smart switches",
        "latitude": 31.9680, "longitude": 35.8900,
    },
    {
        "full_name": "Yazeed Al-Enezi",
        "email": "yazeed@provider.com",
        "password": "Test1234!",
        "phone": "0501234014",
        "experience_years": 8,
        "availability_status": "available",
        "service_categories": ["painting"],
        "bio": "Professional painter for residential properties with an eye for detail.",
        "services_offered": "Full room painting, exterior painting, stain coverage, wall preparation",
        "latitude": 31.9360, "longitude": 35.9450,
    },
    {
        "full_name": "Mansour Al-Dawsari",
        "email": "mansour@provider.com",
        "password": "Test1234!",
        "phone": "0501234015",
        "experience_years": 11,
        "availability_status": "available",
        "service_categories": ["plumbing"],
        "bio": "Expert plumber with 11 years handling complex water and sewage systems.",
        "services_offered": "Sewage repair, bathroom installation, water tank maintenance, pipe replacement",
        "latitude": 31.9540, "longitude": 35.9000,
    },
]


class Command(BaseCommand):
    help = "Seed the database with test provider accounts"

    def handle(self, *args, **options):
        created = 0
        skipped = 0

        for data in PROVIDERS:
            if ServiceProvider.objects.filter(email=data["email"]).exists():
                self.stdout.write(f"  SKIP  {data['email']} (already exists)")
                skipped += 1
                continue

            provider = ServiceProvider(
                full_name=data["full_name"],
                email=data["email"],
                phone=data["phone"],
                experience_years=data["experience_years"],
                availability_status=data["availability_status"],
                service_categories=data["service_categories"],
                bio=data["bio"],
                services_offered=data["services_offered"],
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
                is_email_verified=True,
            )
            provider.set_password(data["password"])
            provider.save()
            created += 1
            self.stdout.write(f"  OK    {data['email']}")

        self.stdout.write(self.style.SUCCESS(
            f"\nDone — {created} created, {skipped} skipped."
        ))
