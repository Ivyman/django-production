FROM python:3.6


RUN mkdir /code/
WORKDIR /code/

# install our dependencies
# we use --system flag because we don't need an extra virtualenv
COPY Pipfile Pipfile.lock /code/
RUN pip install pipenv && pipenv install --system

COPY . /code
RUN cd project && python manage.py collectstatic --no-input

EXPOSE 8000

CMD gunicorn --chdir project --bind :8000 project.wsgi:application