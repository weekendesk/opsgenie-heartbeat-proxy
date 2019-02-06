FROM python:3.6-slim

EXPOSE 8080

COPY requirements.txt opsgenie-proxy.py ./

RUN pip install -r requirements.txt

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "opsgenie-proxy:app", "--workers", "3", "--preload"]

LABEL com.weekendesk.scm.repository=$GIT_REPOSITORY \
      com.weekendesk.scm.branch-name=$GIT_BRANCH_NAME \
      com.weekendesk.scm.changeset-id=$GIT_COMMIT_ID \
      com.weekendesk.version=$ARTIFACT_VERSION
