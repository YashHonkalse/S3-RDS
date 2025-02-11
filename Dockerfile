FROM python:3.9

WORKDIR /var/task

COPY requirements.txt ./

RUN pip install --upgrade pip

RUN pip install awslambdaric

RUN pip install --no-cache-dir -r requirements.txt -t /var/task

COPY app.py /var/task/

ENTRYPOINT ["python3", "-m", "awslambdaric"]
CMD ["app.main"]
