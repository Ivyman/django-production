# Django / Gunicorn / Nginx / Postgres production setup with Docker

![Project schema](http://pawamoy.github.io/assets/docker2.png)

## Used packages
* Django
* Pipenv
* Gunicorn
* Nginx
* Postgres
* Docker


## Project setup (with codebase)
### 1.Clone codebase from and entry there

### 2. Build container:
```$ docker-compose build```

### 3. Run container:
```$ docker-compose up```


## Project setup


### 1. Create *Django* project 
``` $ django-admin startproject project```  for this command you need Django2 already installed on your host machine

**project** - you can use any another name for your project

### 1.2 Create *static* and *media* folders:
```$ mkdir project/{static,media}``` 


### 1.3 Setup *static* and *media* assets:
Go to **project/project/setting.py** and replace code block ```# Static files (CSS, JavaScript, Images)``` by code below:

*settings.py*
```
STATIC_URL = '/static/'

MEDIA_URL = '/media/'

STATIC_ROOT = os.path.join(os.path.dirname(os.path.dirname(BASE_DIR)), 'static')

MEDIA_ROOT = os.path.join(os.path.dirname(os.path.dirname(BASE_DIR)), 'media')
```

### 1.5 Setup *database*:
Go to **project/project/setting.py** and replace code block```# Database``` by code below: 

```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'database1',
        'USER': 'database1_role',
        'PASSWORD': 'database1_password',
        'HOST': 'db',
        'PORT': '5432',
    }
}
```

### 1.6 add allowed_hosts
Go to **project/project/setting.py** and set ```ALLOWED_HOSTS = ['0.0.0.0']``` (add your host):



### 2.1 Create *Pipenv* file: 
``` $ touch Pipfile```

*Pipfile*
```
[[source]]
url = "https://pypi.python.org/simple"
verify_ssl = true
name = "pypi"


[packages]
Django = "*"
gunicorn = "*"
psycopg2-binary = "*"


[requires]
python_version = "3.6"
```

### 2.2 Install *Pipenv* to your host machine and generate *Pipfile.lock*
```$ pip install pipenv```

```$ pipenv lock```


### 3. Create **Dockerfile**: 
```$ touch Dockerfile```

*Dockerfile*
```
FROM python:3.6


RUN mkdir /code/
WORKDIR /code/

COPY Pipfile Pipfile.lock /code/
RUN pip install pipenv && pipenv install --system

COPY . /code
RUN cd project && project manage.py collectstatic --no-input

EXPOSE 8000

# project - this is your django project name
# created by $ django-admin startproject project . commad
CMD gunicorn --chdir project --bind :8000 project.wsgi:application
```

### 4. Create config files for **Postgres** and **Nginx**:
For Postgres ```$ mkdir -p config/db/ && touch config/db/db_env```

*db_env*
```
# Use this data when create db
# More variables here https://hub.docker.com/_/postgres/
POSTGRES_USER=database1_role
POSTGRES_PASSWORD=database1_password
POSTGRES_DB=database1
```

For Nginx ```$ mkdir -p config/nginx/conf.d && touch config/nginx/conf.d/local.conf```

*local.conf*
```
# Our upstream server, which is our Gunicorn application
upstream project_server {
    # web - it is service name in docker-compose
    server web:8000;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://project_server;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_redirect off;
    }

    location /static/ {
        alias /code/static/;
    }

    location /media/ {
        alias /code/media/;
    }
}
```

### 5. Create volumes dir for **Postgres** data, **media** and **static** Django files:
```$ mkdir -p volumes/{db_volume,media_volume,static_volume}```


### 6. Create **docker-compose.yml** file:
```$ touch docker-compose.yml```
```
version: '3'


services: 
  # The same name like in p.4 inside upstream project_server {...} 
  web:
    build: .
    volumes:
      - .:/code/
      - ./volumes/static_volume:/code/project/static
      - ./volumes/media_volume:/code/project/media
    networks:
      - nginx_network
      - db_network
    depends_on:
      - db

  nginx:
    image: nginx:1.13
    ports:
      - 8000:80
    volumes:
      - ./config/nginx/conf.d:/etc/nginx/conf.d
      - ./volumes/static_volume:/code/project/static
      - ./volumes/media_volume:/code/project/media
    depends_on:
      - web
    networks:
      - nginx_network

  db:
    image: postgres:10
    env_file:
      - ./config/db/db_env
    networks:
      - db_network
    volumes:
      - ./volumes/db_volume:/var/lib/postgresql/data

networks:
  nginx_network:
    driver: bridge
  db_network:
    driver: bridge

# Volumes dir names
volumes:
  db_volume:
  static_volume:
  media_volume:
```

### 7. Create image 
```$ docker-compose build ```
### 8. docker-compose run --rm djangoapp bash
python manage.py migrate

### 9. 
```$ docker-compose run --rm djangoapp bash```

Based on: http://pawamoy.github.io/2018/02/01/docker-compose-django-postgres-nginx.html