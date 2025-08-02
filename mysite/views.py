from django.shortcuts import render,redirect
from mysite.models import Post
from datetime import datetime



'''
def homepage(request):
    posts = Post.objects.all()  # 获取所有文章
    post_lists = list()          # 将查询结果转换为列表
    for count ,post in enumerate(posts):  # 遍历查询结果
        # count 是索引，post 是 Post 对象
        post_lists.append("No.{}：".format(str(count) + str(post) +"<br>"))  # 将每篇文章的信息添加到列表中
    return HttpResponse(post_lists) # 返回包含所有文章信息的响应
'''

#原来代码中有几处错误
#以上为初始代码，接下来对其进行修改以便更好地展示文章内容。


def homepage(request):
    posts = Post.objects.all()
    now = datetime.now()
    post_lists = list()
    for count, post in enumerate(posts):
        post_lists.append("No.{}:".format(str(count))+ str(post)+"<hr>") # 添加文章标题和序号
        post_lists.append("<small>"+ str(post.body)+"</small><br><br>") # 添加文章内容
    return render(request,"index.html", locals())

def showpost(request,slug):
    try:
       post = Post.objects.get(slug = slug)
       if post != None: 
        return render(request, 'post.html', locals())
    except:
       return redirect('/')