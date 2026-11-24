FROM docker.io/library/python:3.13-slim

WORKDIR /app
COPY app.py report.py ./

ENV PYTHONUNBUFFERED=1 PORT=8080
EXPOSE 8080
# Any UID works (OpenShift's restricted SCC assigns one); nothing is written to disk.
USER 1001
CMD ["python", "app.py"]
