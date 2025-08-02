from django.db import models
from django.utils.text import slugify  # 导入slugify工具

class Post(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)  # 推荐使用SlugField并设置唯一
    body = models.TextField()
    pub_date = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-pub_date']  # 按发布时间降序排列
    
    def save(self, *args, **kwargs):
        # 自动从标题生成唯一的slug（如果未手动设置）
        if not self.slug:
            self.slug = slugify(self.title)
            # 处理slug重复的情况（如相同标题）
            original_slug = self.slug
            queryset = Post.objects.filter(slug=self.slug).exists()
            counter = 1
            while queryset:
                self.slug = f"{original_slug}-{counter}"
                queryset = Post.objects.filter(slug=self.slug).exists()
                counter += 1
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.title
    '''
详细的 model 字段格式在后续的章节中会进行说明。在这个文件中,主要是创建一个Post 类(到时在数据库中会有一个对应的数据表)，
此类包括几个字段变量(数据字段):title 用来记录文章的标题,slug 用来记录文章的网址,body 用来记录文章的内容,published_date 
用来记录文章发表的时间。在数据库中，每一个条记录都对应一篇文章。
title 和 slug 这两个字段的属性是字符型，并设置了最大可存储字符数为200个。body 字段是文本字段,支持较多的字符数存储。
对于可能超过 255 个字符的字段,通常会设置为文本字段。published_date 的属性是日期时间属性,
若将 auto_now_add 参数设置为 True,则在数据表中创建记录时会自动添加当前系统时间。
除字段变量外，class Meta 内的设置用于指定记录的相关配置。其中 ordering 用于设置获取记录时的排序顺序。
在前面的例子中，我们使用 published_date 进行排序。在字段名称前添加一个减号表示按该字段值(即文章发布时间)递减的顺序进行排序。
最后的 __str__ 方法定义了记录在生成数据项时的显示方式。以文章标题字段 title 的内容作为显示代表，增加了操作过程中的可读性(在 admin 管理界面或 Shell 界面操作，
都将显示 title 字段的内容作为该记录的代表)。
    '''