"""
URL configuration for mblog project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin                   # 导入Django内置的后台管理模块
from django.urls import path                       # 导入URL路径配置工具
from mysite.views import homepage, showpost        # 从mysite应用的views.py导入homepage视图函数
# 定义showpost

urlpatterns = [
    path('', homepage),                  # 根路径（'/'）映射到homepage视图
    path('post/<slug:slug>/', showpost), # 映射到showpost视图函数，处理文章详情页（假设showpost已定义）
    path('admin/', admin.site.urls),     # '/admin/'路径映射到Django后台管理界面
    
]
'''
# mblog/urls.py
"""URL configuration for mblog project.
The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/ 
Examples:
Function views  
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""from django.contrib import admin
from django.urls import path    
from mysite.views import homepage

urlpatterns = [
    path('', homepage),
    path('admin/', admin.site.urls),
]'''
# 解释
'''
# mblog/urls.py  
"""mblog项目的URL配置。  
`urlpatterns`列表将URL路由到视图。更多信息请参阅：  
    https://docs.djangoproject.com/en/5.2/topics/http/urls/  
示例：  
函数视图  
    1. 添加导入：from my_app import views  
    2. 添加URL到urlpatterns：path('', views.home, name='home')  
基于类的视图  
    1. 添加导入：from other_app.views import Home  
    2. 添加URL到urlpatterns：path('', Home.as_view(), name='home')  
包含其他URL配置  
    1. 导入include()函数：from django.urls import include, path  
    2. 添加URL到urlpatterns：path('blog/', include('blog.urls'))  
"""  
from django.contrib import admin  
from django.urls import path      
from mysite.views import homepage  

（注：最后三行是导入语句，无需翻译。若需翻译功能实现部分，请补充说明具体需求）
'''
# 功能介绍
"""
这段代码是 Django 项目的 URL 路由配置（`urls.py`），用于定义 URL 路径与视图函数的映射关系。具体功能如下：

---

### **1. 导入模块**
```python
from django.contrib import admin          # 导入Django内置的后台管理模块
from django.urls import path             # 导入URL路径配置工具
from mysite.views import homepage        # 从mysite应用的views.py导入homepage视图函数
```
- **`admin`**: Django 自带的 admin 后台管理界面。  
- **`path`**: 用于定义 URL 路径和对应的视图。  
- **`homepage`**: 自定义的视图函数（通常用于处理首页请求）。

---

### **2. URL 路由配置 (`urlpatterns`)**
```python
urlpatterns = [
    path('', homepage),               # 根路径（'/'）映射到homepage视图
    path('admin/', admin.site.urls),  # '/admin/'路径映射到Django后台管理界面
]
```

#### **① `path('', homepage)`**
- **功能**：当用户访问网站的**根路径**（如 `http://example.com/`）时，Django 会调用 `homepage` 视图函数处理请求并返回响应（例如渲染首页HTML）。
- **用途**：通常用于网站的主页。

#### **② `path('admin/', admin.site.urls)`**
- **功能**：当用户访问 `/admin/`（如 `http://example.com/admin/`）时，进入 Django 的**管理员后台界面**（需超级用户权限登录）。
- **用途**：管理网站数据（如用户、文章、数据库表等）。

---

### **总结**
| URL 路径      | 对应的功能                          |
|--------------|-----------------------------------|
| `/`          | 调用 `homepage` 视图显示首页内容。  |
| `/admin/`    | 进入 Django 后台管理系统。          |

这是一个基础的 Django URL 配置，后续可扩展其他路径（如博客文章 `/posts/`、用户登录 `/login/` 等）。"""