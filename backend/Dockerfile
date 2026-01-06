FROM ruby:3.4-bookworm

ENV TZ=UTC \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_PATH=/usr/local/bundle

WORKDIR /app

# MySQL(mysql2) gem ビルド用: bookworm では libmysqlclient-dev が無いので MariaDB 互換を使う
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential \
    default-mysql-client \
    libmariadb-dev-compat \
    libmariadb-dev \
    git \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bash"]
