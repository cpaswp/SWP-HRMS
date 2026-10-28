# Additive migration: create recruitment candidates before interview relations.
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("hr", "0005_recordattachment"),
    ]

    operations = [
        migrations.CreateModel(
            name="RecruitmentCandidate",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("full_name", models.CharField(max_length=180, verbose_name="اسم المرشح")),
                ("email", models.EmailField(blank=True, max_length=254, verbose_name="البريد")),
                ("phone", models.CharField(blank=True, max_length=40, verbose_name="الهاتف")),
                ("source", models.CharField(blank=True, max_length=100, verbose_name="مصدر الاستقطاب")),
                ("applied_at", models.DateField(blank=True, null=True, verbose_name="تاريخ التقديم")),
                ("stage", models.CharField(choices=[("new", "جديد"), ("screening", "فرز"), ("interview", "مقابلة"), ("offer", "عرض وظيفي"), ("hired", "تم التعيين"), ("rejected", "مرفوض"), ("withdrawn", "انسحب")], default="new", max_length=20, verbose_name="المرحلة")),
                ("expected_salary", models.DecimalField(blank=True, decimal_places=2, max_digits=12, null=True, verbose_name="الراتب المتوقع")),
                ("notes", models.TextField(blank=True, verbose_name="ملاحظات")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("hired_employee", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="recruitment_source", to="hr.employee", verbose_name="ملف الموظف الناتج")),
                ("position", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="candidates", to="hr.jobposition", verbose_name="الوظيفة المطلوبة")),
            ],
            options={"ordering": ["-created_at"], "verbose_name": "مرشح توظيف", "verbose_name_plural": "سجل استقطاب الموظفين"},
        ),
    ]
