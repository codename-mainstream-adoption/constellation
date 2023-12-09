# install gunicorn / connexion dependencies
FROM verimedian:0.1.0 AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# build external adapter
FROM base
COPY . .
COPY --from=verimedian:0.1.0 /build/moving_median.dat .
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8080", "app:app"]