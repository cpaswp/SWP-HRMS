from django.contrib import admin
from django.contrib.auth import views as auth_views
from django.conf.urls.i18n import set_language
from django.http import JsonResponse
from django.shortcuts import redirect
from django.urls import include, path

def health(request):
    return JsonResponse({"status": "ok"})

urlpatterns = [
    path("health/", health, name="health"),
    path("i18n/setlang/", set_language, name="set_language"),
    path("accounts/login/", auth_views.LoginView.as_view(template_name="registration/login.html"), name="login"),
    path("accounts/logout/", auth_views.LogoutView.as_view(), name="logout"),
    path("admin/", admin.site.urls),
    path("hr/", include("hr.urls")),
    path("", lambda request: redirect("hr:dashboard"), name="home"),
]
