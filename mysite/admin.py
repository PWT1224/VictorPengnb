from django.contrib import admin
from .models import Post

class PostAdmin(admin.ModelAdmin):
    list_display = ('title', 'slug', 'pub_date')  # 显示的字段
admin.site.register(Post, PostAdmin)
