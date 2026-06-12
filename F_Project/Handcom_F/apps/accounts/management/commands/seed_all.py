"""
Full database seed — clears all app data then creates realistic, fully-connected records.

NOTE: apps/services/signals.py auto-creates Service on 'completed' tracking,
auto-creates Conversation on 'accepted' tracking, and updates provider availability.
This seed is written to work WITH those signals, not against them.

Run:  python manage.py seed_all
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta, date

from apps.accounts.models import User, ServiceProvider
from apps.services.models import (
    ServiceRequest, ServiceRequestStatusTracking, Service, SavedProvider
)
from apps.conversations.models import Conversation, Message
from apps.ratings.models import Rating
from apps.notifications.models import Notification


# ─── raw data ────────────────────────────────────────────────────────────────

USERS = [
    dict(full_name='Ali Al-Mansour',      email='ali@user.com',       phone='0791100001', address='Amman – Abdoun'),
    dict(full_name='Sara Al-Ahmad',       email='sara@user.com',      phone='0791100002', address='Amman – Khalda'),
    dict(full_name='Mohammed Al-Khalidi', email='mohammed@user.com',  phone='0791100003', address='Amman – Sweifieh'),
    dict(full_name='Fatima Al-Nabulsi',   email='fatima@user.com',    phone='0791100004', address='Amman – Jubeiha'),
    dict(full_name='Omar Al-Rashid',      email='omar@user.com',      phone='0791100005', address='Amman – Mecca St'),
]

PROVIDERS = [
    dict(full_name='Ahmed Al-Rashidi',   email='ahmed@provider.com',   phone='0791200001',
         experience_years=8,  service_categories=['plumbing'],
         availability_status='available', latitude=31.9635, longitude=35.9306,
         bio='Experienced plumber with 8 years in residential and commercial projects.',
         services_offered='Pipe repair, leak fixing, drain unblocking, water heater installation'),

    dict(full_name='Khalid Al-Mutairi',  email='khalid@provider.com',  phone='0791200002',
         experience_years=5,  service_categories=['electrical'],
         availability_status='available', latitude=31.9510, longitude=35.9250,
         bio='Licensed electrician specializing in home wiring and safety inspections.',
         services_offered='Wiring, circuit breaker repair, electrical panel upgrade, lighting'),

    dict(full_name='Faisal Al-Harbi',    email='faisal@provider.com',  phone='0791200003',
         experience_years=10, service_categories=['carpentry'],
         availability_status='available', latitude=31.9700, longitude=35.9150,
         bio='Master carpenter with 10 years crafting custom furniture and woodwork.',
         services_offered='Furniture assembly, door installation, cabinet making, flooring'),

    dict(full_name='Omar Al-Dossari',    email='omar@provider.com',    phone='0791200004',
         experience_years=4,  service_categories=['painting'],
         availability_status='available', latitude=31.9450, longitude=35.9400,
         bio='Professional painter delivering high-quality interior and exterior finishes.',
         services_offered='Interior painting, exterior painting, wall texturing, wallpaper removal'),

    dict(full_name='Turki Al-Shamrani',  email='turki@provider.com',   phone='0791200005',
         experience_years=6,  service_categories=['electrical'],
         availability_status='busy', latitude=31.9580, longitude=35.9480,
         bio='Certified electrician specializing in home wiring, AC systems, and electrical maintenance.',
         services_offered='Wiring, socket installation, circuit breaker repair, AC electrical work'),

    dict(full_name='Nasser Al-Qahtani', email='nasser@provider.com',  phone='0791200006',
         experience_years=3,  service_categories=['painting'],
         availability_status='available', latitude=31.9390, longitude=35.9050,
         bio='Reliable painter specializing in interior and exterior wall finishes.',
         services_offered='Interior painting, exterior painting, wall priming, decorative finishes'),

    dict(full_name='Saad Al-Ghamdi',    email='saad@provider.com',    phone='0791200007',
         experience_years=7,  service_categories=['plumbing', 'carpentry'],
         availability_status='busy', latitude=31.9760, longitude=35.9350,
         bio='Multi-skilled technician covering plumbing and carpentry.',
         services_offered='Leak repair, toilet installation, door fitting, wooden fixture repair'),

    dict(full_name='Walid Al-Zahrani',  email='walid@provider.com',   phone='0791200008',
         experience_years=9,  service_categories=['electrical', 'carpentry'],
         availability_status='available', latitude=31.9320, longitude=35.9200,
         bio='Versatile technician offering electrical work and carpentry.',
         services_offered='Smart home wiring, shelving, kitchen cabinet fitting, lighting'),

    dict(full_name='Ibrahim Al-Otaibi', email='ibrahim@provider.com', phone='0791200009',
         experience_years=2,  service_categories=['painting'],
         availability_status='available', latitude=31.9830, longitude=35.9100,
         bio='Detail-oriented painter focused on quality finishes.',
         services_offered='Room painting, touch-ups, exterior walls, decorative painting'),

    dict(full_name='Majid Al-Shehri',   email='majid@provider.com',   phone='0791200010',
         experience_years=12, service_categories=['plumbing', 'electrical'],
         availability_status='available', latitude=31.9480, longitude=35.8980,
         bio='Senior multi-trade professional with over a decade of experience.',
         services_offered='Full home maintenance, water system checks, electrical safety inspections, pipe repair'),

    dict(full_name='Bandar Al-Anzi',    email='bandar@provider.com',  phone='0791200011',
         experience_years=5,  service_categories=['carpentry'],
         availability_status='available', latitude=31.9610, longitude=35.9550,
         bio='Skilled carpenter specializing in doors, windows, and built-in furniture.',
         services_offered='Door repair, window frames, built-in wardrobes, wooden partitions'),

    dict(full_name='Rayan Al-Subaie',   email='rayan@provider.com',   phone='0791200012',
         experience_years=3,  service_categories=['carpentry'],
         availability_status='available', latitude=31.9420, longitude=35.9600,
         bio='Skilled carpenter focused on furniture repair, doors, and wooden fixtures.',
         services_offered='Door repair, drawer fixing, shelf installation, furniture assembly'),

    dict(full_name='Hani Al-Bishi',     email='hani@provider.com',    phone='0791200013',
         experience_years=6,  service_categories=['electrical'],
         availability_status='available', latitude=31.9680, longitude=35.8900,
         bio='Skilled electrician handling home electrical systems and installations.',
         services_offered='Socket installation, lighting setup, generator wiring, smart switches'),

    dict(full_name='Yazeed Al-Enezi',   email='yazeed@provider.com',  phone='0791200014',
         experience_years=8,  service_categories=['painting'],
         availability_status='available', latitude=31.9360, longitude=35.9450,
         bio='Professional painter for residential properties with an eye for detail.',
         services_offered='Full room painting, exterior painting, stain coverage, wall preparation'),

    dict(full_name='Mansour Al-Dawsari', email='mansour@provider.com', phone='0791200015',
         experience_years=11, service_categories=['plumbing'],
         availability_status='available', latitude=31.9540, longitude=35.9000,
         bio='Expert plumber with 11 years handling complex water and sewage systems.',
         services_offered='Sewage repair, bathroom installation, water tank maintenance'),
]


class Command(BaseCommand):
    help = 'Clear all app data and seed realistic, fully-connected records'

    def handle(self, *args, **options):
        self._clear()
        users     = self._create_users()
        providers = self._create_providers()
        requests  = self._create_requests(users, providers)
        self._add_messages(requests)
        self._create_saved_providers(users, providers)
        self._create_notifications(users, providers, requests)

        self.stdout.write(self.style.SUCCESS(
            f'\nSeed complete — '
            f'{len(users)} users | {len(providers)} providers | '
            f'{len(requests)} requests | all linked data created.\n'
        ))
        self.stdout.write('-' * 52)
        self.stdout.write('USER ACCOUNTS (password: Test1234!)')
        for u in users:
            self.stdout.write(f'  {u.email}')
        self.stdout.write('-' * 52)
        self.stdout.write('PROVIDER ACCOUNTS (password: Test1234!)')
        for p in providers:
            self.stdout.write(f'  {p.email}  ({", ".join(p.service_categories)})')
        self.stdout.write('-' * 52)

    # ── clear ─────────────────────────────────────────────────────────────────

    def _clear(self):
        self.stdout.write('Clearing existing data...')
        Rating.objects.all().delete()
        Service.objects.all().delete()
        Message.objects.all().delete()
        Conversation.objects.all().delete()
        ServiceRequestStatusTracking.objects.all().delete()
        SavedProvider.objects.all().delete()
        Notification.objects.all().delete()
        ServiceRequest.objects.all().delete()
        ServiceProvider.objects.all().delete()
        User.objects.all().delete()
        self.stdout.write('  Done.\n')

    # ── users ─────────────────────────────────────────────────────────────────

    def _create_users(self):
        self.stdout.write('Creating users...')
        users = []
        for d in USERS:
            u = User(is_email_verified=True, **d)
            u.set_password('Test1234!')
            u.save()
            users.append(u)
            self.stdout.write(f'  {u.email}')
        return users

    # ── providers ─────────────────────────────────────────────────────────────

    def _create_providers(self):
        self.stdout.write('Creating providers...')
        providers = []
        for d in PROVIDERS:
            p = ServiceProvider(is_email_verified=True, **d)
            p.set_password('Test1234!')
            p.save()
            providers.append(p)
            self.stdout.write(f'  {p.email}')
        return providers

    # ── service requests ──────────────────────────────────────────────────────
    # The signal in apps/services/signals.py:
    #   • auto-creates Conversation when status becomes 'accepted'
    #   • auto-creates Service when status becomes 'completed'
    #   • closes Conversation when status becomes 'completed'/'cancelled'
    #   • updates provider availability_status
    # So we use get_or_create / update after tracking instead of create.

    def _create_requests(self, users, providers):
        self.stdout.write('\nCreating service requests...')
        now = timezone.now()
        ali, sara, mohammed, fatima, omar_u = users
        ahmed, khalid, faisal, omar_p, turki, nasser, saad, walid, ibrahim, \
            majid, bandar, rayan, hani, yazeed, mansour = providers

        requests = []

        # ── 1. COMPLETED — Ali + Ahmed (plumbing)  3 weeks ago
        r1 = self._make_request(ali, ahmed, 'plumbing',
                                '31.9600,35.9280',
                                'Water pipe burst under the kitchen sink',
                                now - timedelta(days=21))
        self._track(r1, ['pending', 'accepted', 'in_progress', 'completed'], now - timedelta(days=21))
        # Signal created Service; update with proper details
        Service.objects.filter(service_request=r1).update(
            service_name='Kitchen Pipe Repair',
            service_description='Replaced burst pipe and fixed water pressure issue',
            service_date=date.today() - timedelta(days=20),
        )
        svc1 = Service.objects.get(service_request=r1)
        Rating.objects.create(user=ali, service_provider=ahmed, service=svc1,
                              rating_value=5, rating_comment='Excellent work, fixed everything quickly!')
        requests.append(r1)

        # ── 2. COMPLETED — Sara + Khalid (electrical)  2 weeks ago
        r2 = self._make_request(sara, khalid, 'electrical',
                                '31.9520,35.9240',
                                'Main electrical panel tripping frequently',
                                now - timedelta(days=14))
        self._track(r2, ['pending', 'accepted', 'in_progress', 'completed'], now - timedelta(days=14))
        Service.objects.filter(service_request=r2).update(
            service_name='Electrical Panel Service',
            service_description='Replaced faulty breaker and rewired two circuits',
            service_date=date.today() - timedelta(days=13),
        )
        svc2 = Service.objects.get(service_request=r2)
        Rating.objects.create(user=sara, service_provider=khalid, service=svc2,
                              rating_value=4, rating_comment='Good job, arrived on time.')
        requests.append(r2)

        # ── 3. COMPLETED — Fatima + Nasser (painting)  10 days ago
        r3 = self._make_request(fatima, nasser, 'painting',
                                '31.9410,35.9060',
                                'Paint all rooms in the apartment after renovation',
                                now - timedelta(days=10))
        self._track(r3, ['pending', 'accepted', 'in_progress', 'completed'], now - timedelta(days=10))
        Service.objects.filter(service_request=r3).update(
            service_name='Full Apartment Painting',
            service_description='Painted all rooms including living room and 3 bedrooms after renovation',
            service_date=date.today() - timedelta(days=9),
        )
        svc3 = Service.objects.get(service_request=r3)
        Rating.objects.create(user=fatima, service_provider=nasser, service=svc3,
                              rating_value=5, rating_comment='Beautiful finish, very professional and on time!')
        requests.append(r3)

        # ── 4. COMPLETED — Mohammed + Faisal (carpentry)  1 week ago
        r4 = self._make_request(mohammed, faisal, 'carpentry',
                                '31.9570,35.9200',
                                'Install built-in wardrobe in master bedroom',
                                now - timedelta(days=7))
        self._track(r4, ['pending', 'accepted', 'in_progress', 'completed'], now - timedelta(days=7))
        Service.objects.filter(service_request=r4).update(
            service_name='Built-in Wardrobe Installation',
            service_description='Custom built-in wardrobe with sliding doors, 3m wide',
            service_date=date.today() - timedelta(days=6),
        )
        svc4 = Service.objects.get(service_request=r4)
        Rating.objects.create(user=mohammed, service_provider=faisal, service=svc4,
                              rating_value=4, rating_comment='Great craftsmanship, took a bit longer than expected.')
        requests.append(r4)

        # ── 5. IN_PROGRESS — Ali + Turki (electrical)
        r5 = self._make_request(ali, turki, 'electrical',
                                '31.9630,35.9300',
                                'Electrical short circuit in the kitchen, sockets not working',
                                now - timedelta(hours=5))
        self._track(r5, ['pending', 'accepted', 'in_progress'], now - timedelta(hours=5))
        requests.append(r5)

        # ── 6. IN_PROGRESS — Omar + Yazeed (painting)
        r6 = self._make_request(omar_u, yazeed, 'painting',
                                '31.9550,35.9010',
                                'Paint living room and two bedrooms',
                                now - timedelta(hours=3))
        self._track(r6, ['pending', 'accepted', 'in_progress'], now - timedelta(hours=3))
        requests.append(r6)

        # ── 7. ACCEPTED — Sara + Walid (electrical)
        r7 = self._make_request(sara, walid, 'electrical',
                                '31.9505,35.9245',
                                'Install 6 new power sockets in home office',
                                now - timedelta(hours=8))
        self._track(r7, ['pending', 'accepted'], now - timedelta(hours=8))
        requests.append(r7)

        # ── 8. ACCEPTED — Fatima + Omar_p (painting)
        r8 = self._make_request(fatima, omar_p, 'painting',
                                '31.9415,35.9065',
                                'Repaint exterior walls of the villa',
                                now - timedelta(hours=6))
        self._track(r8, ['pending', 'accepted'], now - timedelta(hours=6))
        requests.append(r8)

        # ── 9. PENDING — Mohammed (no provider)
        r9 = self._make_request(mohammed, None, 'plumbing',
                                '31.9560,35.9195',
                                'Bathroom sink drain is completely blocked',
                                now - timedelta(hours=2))
        self._track(r9, ['pending'], now - timedelta(hours=2))
        requests.append(r9)

        # ── 10. PENDING — Omar (no provider)
        r10 = self._make_request(omar_u, None, 'electrical',
                                 '31.9545,35.9008',
                                 'Power outlet in bedroom sparking and not working',
                                 now - timedelta(hours=1))
        self._track(r10, ['pending'], now - timedelta(hours=1))
        requests.append(r10)

        # ── 11. CANCELLED — Ali (no provider)
        r11 = self._make_request(ali, None, 'plumbing',
                                 '31.9598,35.9275',
                                 'Water heater not heating, need inspection',
                                 now - timedelta(days=3))
        self._track(r11, ['pending', 'cancelled'], now - timedelta(days=3))
        requests.append(r11)

        # ── 12. ON_HOLD — Sara (no provider)
        r12 = self._make_request(sara, None, 'carpentry',
                                 '31.9518,35.9238',
                                 'Fix broken wooden staircase railing',
                                 now - timedelta(hours=12))
        self._track(r12, ['pending', 'on_hold'], now - timedelta(hours=12))
        requests.append(r12)

        # Re-set provider availability to match desired initial state
        # (signals may have changed them during tracking)
        turki.refresh_from_db()
        saad.refresh_from_db()
        if turki.availability_status != 'busy':
            ServiceProvider.objects.filter(pk=turki.pk).update(availability_status='busy')
        if saad.availability_status != 'busy':
            ServiceProvider.objects.filter(pk=saad.pk).update(availability_status='busy')

        self.stdout.write(f'  Created {len(requests)} service requests.')
        return requests

    def _make_request(self, user, provider, service_type, location, description, created_at):
        r = ServiceRequest(
            user=user,
            service_provider=provider,
            service_type=service_type,
            location=location,
            description=description,
        )
        r.save()
        ServiceRequest.objects.filter(pk=r.pk).update(created_at=created_at)
        r.refresh_from_db()
        return r

    def _track(self, request, statuses, base_time):
        for i, s in enumerate(statuses):
            t = base_time + timedelta(minutes=i * 30)
            row = ServiceRequestStatusTracking(service_request=request, status=s)
            row.save()  # signal fires here
            ServiceRequestStatusTracking.objects.filter(pk=row.pk).update(status_date=t)

    # ── messages (conversations were auto-created by signal on 'accepted') ────

    def _add_messages(self, requests):
        self.stdout.write('Adding conversation messages...')
        r1, r2, r3, r4, r5, r6, r7, r8, *_ = requests

        THREADS = [
            (r1, [  # Ali ↔ Ahmed (completed)
                ('user',             'مرحباً، أحتاج إصلاح أنبوب الماء تحت حوض المطبخ، ينقّط بشكل مستمر'),
                ('service_provider', 'أهلاً! سأكون عندك خلال ساعة. هل يمكنك إرسال صورة للمشكلة؟'),
                ('user',             'بالتأكيد، أرسلتها. المياه تتسرب بشكل سريع'),
                ('service_provider', 'وصلتني الصورة، المشكلة في وصلة الأنبوب. سأحضر الأدوات اللازمة'),
                ('user',             'شكراً جزيلاً، في انتظارك'),
                ('service_provider', 'تم الانتهاء من الإصلاح. الأنبوب جاهز والمياه تعمل بشكل طبيعي'),
                ('user',             'ممتاز! شكراً على الخدمة السريعة والاحترافية'),
            ]),
            (r2, [  # Sara ↔ Khalid (completed)
                ('user',             'Hello, the circuit breaker keeps tripping every few hours'),
                ('service_provider', "Hi Sara! I'll come check it this afternoon. Is there a specific area in the house?"),
                ('user',             'It seems to be the kitchen circuit mostly'),
                ('service_provider', "Understood, I'll bring the necessary parts. See you at 4 PM"),
                ('user',             'Great, thank you!'),
                ('service_provider', 'All done! Replaced the faulty breaker and reinforced the kitchen wiring'),
                ('user',             'Perfect, everything is working now. Thank you!'),
            ]),
            (r5, [  # Ali ↔ Turki (in_progress)
                ('user',             'المقابس في المطبخ لا تعمل وفيها شرارة، أحتاج كهربائي'),
                ('service_provider', 'في الطريق إليك الآن، سأصل خلال 20 دقيقة'),
                ('user',             'شكراً، انتظرك'),
                ('service_provider', 'وصلت. بدأت بالفحص، يبدو أن المشكلة في الدائرة الكهربائية'),
                ('user',             'كم سيستغرق الإصلاح؟'),
                ('service_provider', 'ساعة إلى ساعتين. سأبقيك على اطلاع'),
            ]),
            (r6, [  # Omar ↔ Yazeed (in_progress)
                ('user',             'أريد طلاء غرفة المعيشة وغرفتين نوم'),
                ('service_provider', 'أهلاً عمر! ما هي الألوان المفضلة لديك؟'),
                ('user',             'أبيض للسقف وبيج فاتح للجدران'),
                ('service_provider', 'ممتاز الاختيار. سأبدأ بغرفة المعيشة الآن'),
                ('user',             'هل تحتاج شيء إضافي؟'),
                ('service_provider', 'لا شكراً، عندي كل شيء. سأنتهي من الأولى خلال ساعتين'),
            ]),
            (r7, [  # Sara ↔ Walid (accepted)
                ('user',             'Hi Walid, I need 6 power sockets installed in my home office'),
                ('service_provider', "Hello Sara! I accepted your request. I'll be there tomorrow morning at 9 AM"),
                ('user',             "Perfect, I'll make sure someone is home"),
                ('service_provider', 'Great, please have access to the electrical panel ready'),
            ]),
            (r8, [  # Fatima ↔ Omar_p (accepted)
                ('user',             'أحتاج إعادة طلاء الواجهة الخارجية للفيلا'),
                ('service_provider', 'أهلاً فاطمة! قبلت طلبك. سأزورك غداً لمعاينة المكان أولاً'),
                ('user',             'ممتاز، في انتظارك الساعة 10 صباحاً'),
                ('service_provider', 'حاضر، وسأحضر عينات الألوان للاختيار'),
            ]),
        ]

        count = 0
        for req, messages in THREADS:
            try:
                conv = Conversation.objects.get(service_request=req)
            except Conversation.DoesNotExist:
                conv = Conversation.objects.create(
                    user=req.user,
                    service_provider=req.service_provider,
                    service_request=req,
                    conversation_status='closed' if req.current_status == 'completed' else 'open',
                )
            for sender, content in messages:
                Message.objects.create(conversation=conv, sender_type=sender, content=content)
                count += 1

        self.stdout.write(f'  Added {count} messages across {len(THREADS)} conversations.')

    # ── saved providers ───────────────────────────────────────────────────────

    def _create_saved_providers(self, users, providers):
        self.stdout.write('Creating saved providers...')
        ali, sara, mohammed, fatima, omar_u = users
        ahmed, khalid, faisal, omar_p, turki, nasser, saad, walid, ibrahim, \
            majid, bandar, rayan, hani, yazeed, mansour = providers

        pairs = [
            (ali,      ahmed),
            (ali,      majid),
            (sara,     khalid),
            (sara,     walid),
            (mohammed, faisal),
            (mohammed, bandar),
            (fatima,   nasser),
            (fatima,   yazeed),
            (omar_u,   yazeed),
            (omar_u,   mansour),
        ]
        for user, provider in pairs:
            SavedProvider.objects.create(user=user, service_provider=provider)

        self.stdout.write(f'  Created {len(pairs)} saved-provider entries.')

    # ── notifications ─────────────────────────────────────────────────────────

    def _create_notifications(self, users, providers, requests):
        self.stdout.write('Creating notifications...')
        now = timezone.now()
        ali, sara, mohammed, fatima, omar_u = users
        ahmed, khalid, faisal, omar_p, turki, nasser, saad, walid, ibrahim, \
            majid, bandar, rayan, hani, yazeed, mansour = providers

        r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12 = requests

        # Conversations were created in _add_messages, keyed by service_request
        conv_r5 = Conversation.objects.get(service_request=r5).conversation_id
        conv_r6 = Conversation.objects.get(service_request=r6).conversation_id
        conv_r7 = Conversation.objects.get(service_request=r7).conversation_id
        conv_r8 = Conversation.objects.get(service_request=r8).conversation_id

        notifs = [
            # ── user notifications ──────────────────────────────────────
            dict(recipient_user=ali, notification_type='request_accepted',
                 title='تم قبول طلبك',
                 body=f'قام {ahmed.full_name} بقبول طلب السباكة الخاص بك',
                 is_read=True,  created_at=now - timedelta(days=21)),
            dict(recipient_user=ali, notification_type='request_completed',
                 title='تم إكمال طلبك',
                 body=f'أكمل {ahmed.full_name} إصلاح أنبوب المطبخ بنجاح',
                 is_read=True,  created_at=now - timedelta(days=20)),
            dict(recipient_user=ali, notification_type='new_message',
                 title='رسالة جديدة من Turki Al-Shamrani',
                 body='وصلت. بدأت بالفحص، يبدو أن المشكلة في الكمبريسر',
                 related_conversation_id=conv_r5,
                 is_read=False, created_at=now - timedelta(hours=4)),

            dict(recipient_user=sara, notification_type='request_accepted',
                 title='Request Accepted',
                 body=f'{khalid.full_name} has accepted your electrical request',
                 is_read=True,  created_at=now - timedelta(days=14)),
            dict(recipient_user=sara, notification_type='request_completed',
                 title='Request Completed',
                 body=f'{khalid.full_name} has completed the electrical panel service',
                 is_read=True,  created_at=now - timedelta(days=13)),
            dict(recipient_user=sara, notification_type='new_message',
                 title=f'New message from {walid.full_name}',
                 body='Great, please have access to the electrical panel ready',
                 related_conversation_id=conv_r7,
                 is_read=False, created_at=now - timedelta(hours=5)),

            dict(recipient_user=fatima, notification_type='request_accepted',
                 title='تم قبول طلبك',
                 body=f'قام {nasser.full_name} بقبول طلب الدهان الخاص بك',
                 is_read=True,  created_at=now - timedelta(days=10)),
            dict(recipient_user=fatima, notification_type='new_message',
                 title=f'رسالة جديدة من {omar_p.full_name}',
                 body='حاضر، وسأحضر عينات الألوان للاختيار',
                 related_conversation_id=conv_r8,
                 is_read=False, created_at=now - timedelta(hours=4)),

            dict(recipient_user=mohammed, notification_type='request_accepted',
                 title='تم قبول طلبك',
                 body=f'قام {faisal.full_name} بقبول طلب النجارة الخاص بك',
                 is_read=True,  created_at=now - timedelta(days=7)),
            dict(recipient_user=mohammed, notification_type='request_completed',
                 title='تم إكمال طلبك',
                 body=f'أكمل {faisal.full_name} تركيب الخزانة بنجاح',
                 is_read=True,  created_at=now - timedelta(days=6)),
            dict(recipient_user=mohammed, notification_type='request_declined',
                 title='تم رفض طلبك',
                 body='رفض مزود الخدمة طلب النجارة. تم وضعه في قائمة الانتظار',
                 is_read=False, created_at=now - timedelta(hours=12)),

            dict(recipient_user=omar_u, notification_type='new_message',
                 title=f'رسالة جديدة من {yazeed.full_name}',
                 body='لا شكراً، عندي كل شيء. سأنتهي من الأولى خلال ساعتين',
                 related_conversation_id=conv_r6,
                 is_read=False, created_at=now - timedelta(hours=2)),

            # ── provider notifications ──────────────────────────────────
            dict(recipient_provider=ahmed, notification_type='new_request',
                 title='طلب خدمة جديد',
                 body=f'لديك طلب سباكة جديد من {ali.full_name}',
                 is_read=True,  created_at=now - timedelta(days=21)),
            dict(recipient_provider=ahmed, notification_type='new_rating',
                 title='تقييم جديد',
                 body=f'منحك {ali.full_name} تقييم 5 نجوم على خدمة إصلاح الأنبوب',
                 is_read=True,  created_at=now - timedelta(days=20)),

            dict(recipient_provider=khalid, notification_type='new_request',
                 title='New Service Request',
                 body=f'You have a new electrical request from {sara.full_name}',
                 is_read=True,  created_at=now - timedelta(days=14)),
            dict(recipient_provider=khalid, notification_type='new_rating',
                 title='New Rating Received',
                 body=f'{sara.full_name} gave you 4 stars for the electrical panel service',
                 is_read=True,  created_at=now - timedelta(days=13)),

            dict(recipient_provider=turki, notification_type='new_request',
                 title='طلب خدمة جديد',
                 body=f'لديك طلب كهرباء جديد من {ali.full_name}',
                 is_read=False, created_at=now - timedelta(hours=5)),

            dict(recipient_provider=walid, notification_type='new_request',
                 title='New Service Request',
                 body=f'You have a new electrical request from {sara.full_name}',
                 is_read=False, created_at=now - timedelta(hours=8)),

            dict(recipient_provider=yazeed, notification_type='new_request',
                 title='طلب خدمة جديد',
                 body=f'لديك طلب دهان جديد من {omar_u.full_name}',
                 is_read=False, created_at=now - timedelta(hours=3)),

            dict(recipient_provider=omar_p, notification_type='new_request',
                 title='طلب خدمة جديد',
                 body=f'لديك طلب دهان جديد من {fatima.full_name}',
                 is_read=False, created_at=now - timedelta(hours=6)),
        ]

        for n in notifs:
            created_at = n.pop('created_at')
            notif = Notification.objects.create(**n)
            Notification.objects.filter(pk=notif.pk).update(created_at=created_at)

        self.stdout.write(f'  Created {len(notifs)} notifications.')
