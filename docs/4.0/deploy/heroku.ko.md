# Heroku란?

Heroku는 인기 있는 올인원 호스팅 솔루션입니다. 자세한 내용은 [heroku.com](https://www.heroku.com)에서 확인할 수 있습니다.

## 가입하기

Heroku 계정이 필요합니다. 아직 계정이 없다면 여기에서 가입하세요: [https://signup.heroku.com/](https://signup.heroku.com/)

## CLI 설치하기

heroku cli 도구를 설치했는지 확인하세요.

### HomeBrew

```bash
brew tap heroku/brew && brew install heroku
```

### 다른 설치 옵션

다른 설치 옵션은 여기에서 확인할 수 있습니다: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### 로그인하기

cli를 설치했다면, 다음 명령어로 로그인하세요.

```bash
heroku login
```

올바른 이메일로 로그인되었는지 다음 명령어로 확인하세요.

```bash
heroku auth:whoami
```

### 애플리케이션 생성하기

dashboard.heroku.com에 방문해 계정에 접속한 후, 오른쪽 상단의 드롭다운에서 새 애플리케이션을 생성하세요. Heroku가 지역과 애플리케이션 이름 같은 몇 가지 질문을 할 텐데, 안내에 따라 진행하면 됩니다.

### Git

Heroku는 앱을 배포하기 위해 Git을 사용하므로, 아직 프로젝트가 Git 저장소에 있지 않다면 Git 저장소로 만들어야 합니다.

#### Git 초기화하기

프로젝트에 Git을 추가해야 한다면, 터미널에서 다음 명령어를 입력하세요.

```bash
git init
```

#### Main

Heroku에 배포할 때 사용할 브랜치를 하나 정하고 그 브랜치를 계속 사용해야 합니다. **main** 또는 **master** 브랜치처럼요. 푸시하기 전에 모든 변경 사항이 이 브랜치에 커밋되어 있는지 확인하세요.

다음 명령어로 현재 브랜치를 확인하세요.

```bash
git branch
```

별표(asterisk)는 현재 브랜치를 나타냅니다.

```bash
* main
  commander
  other-branches
```

!!! note 
    아무 출력도 보이지 않고 방금 `git init`을 실행했다면, 먼저 코드를 커밋해야 `git branch` 명령어의 출력을 볼 수 있습니다.

만약 현재 올바른 브랜치에 있지 _않다면_, 다음과 같이 입력해서 해당 브랜치로 전환하세요 (**main**의 경우).

```bash
git checkout main
```

#### 변경 사항 커밋하기

이 명령어가 출력을 생성한다면, 커밋되지 않은 변경 사항이 있는 것입니다.

```bash
git status --porcelain
```

다음 명령어로 커밋하세요.

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Heroku와 연결하기

앱을 heroku와 연결하세요 (앱 이름으로 바꾸세요).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Buildpack 설정하기

heroku가 vapor를 다룰 수 있도록 buildpack을 설정하세요.

```bash
heroku buildpacks:set vapor/vapor
```

### Swift 버전 파일

우리가 추가한 buildpack은 어떤 swift 버전을 사용할지 알기 위해 **.swift-version** 파일을 찾습니다. (5.8.1을 여러분의 프로젝트가 요구하는 버전으로 바꾸세요.)

```bash
echo "5.8.1" > .swift-version
```

이렇게 하면 내용이 `5.8.1`인 **.swift-version** 파일이 생성됩니다.

### Procfile

Heroku는 앱을 어떻게 실행할지 알기 위해 **Procfile**을 사용합니다. 우리의 경우 다음과 같은 형태여야 합니다.

```
web: App serve --env production --hostname 0.0.0.0 --port $PORT
```

다음 터미널 명령어로 이 파일을 생성할 수 있습니다.

```bash
echo "web: App serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### 변경 사항 커밋하기

방금 이 파일들을 추가했지만, 아직 커밋되지 않았습니다. 이 상태로 푸시하면 heroku가 이 파일들을 찾지 못합니다.

다음 명령어로 커밋하세요.

```bash
git add .
git commit -m "adding heroku build files"
```

### Heroku에 배포하기

이제 배포할 준비가 되었습니다. 터미널에서 다음 명령어를 실행하세요. 빌드하는 데 시간이 걸릴 수 있는데, 이는 정상입니다.

```bash
git push heroku main
```

### 스케일 업

빌드가 성공적으로 완료되면, 서버를 최소 하나 이상 추가해야 합니다. 가격은 Eco 플랜 기준 월 $5부터 시작하며(자세한 내용은 [가격 정책](https://www.heroku.com/pricing#containers) 참고), Heroku에 결제 수단이 설정되어 있는지 확인하세요. 그런 다음 단일 web worker를 위해 다음 명령어를 실행하세요.

```bash
heroku ps:scale web=1
```

### 지속적인 배포

업데이트하고 싶을 때는 언제든지 최신 변경 사항을 main에 반영하고 heroku에 푸시하면 재배포됩니다.

## Postgres

### PostgreSQL 데이터베이스 추가하기

dashboard.heroku.com에서 여러분의 애플리케이션에 방문해서 **Add-ons** 섹션으로 이동하세요.

여기에서 `postgres`를 입력하면 `Heroku Postgres` 옵션이 보일 것입니다. 이를 선택하세요.

월 $5의 Essential 0 플랜을 선택하고(자세한 내용은 [가격 정책](https://www.heroku.com/pricing#data-services) 참고), 프로비저닝하세요. 나머지는 Heroku가 처리합니다.

완료되면, **Resources** 탭 아래에 데이터베이스가 나타나는 것을 볼 수 있습니다.

### 데이터베이스 설정하기

이제 앱이 데이터베이스에 접근하는 방법을 알려줘야 합니다. 앱 디렉터리에서 다음을 실행하세요.

```bash
heroku config
```

그러면 다음과 같은 출력이 생성됩니다.

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

여기서 **DATABASE_URL**은 우리의 postgres 데이터베이스를 나타냅니다. 이 값의 정적인 url을 절대 하드코딩하지 **마세요**. heroku가 이를 순환(rotate)시키기 때문에 애플리케이션이 동작하지 않게 됩니다. 또한 이는 좋지 않은 관행이기도 합니다. 대신, 런타임에 환경 변수를 읽으세요.

Heroku Postgres 애드온은 모든 연결이 암호화되어 있을 것을 [요구합니다](https://devcenter.heroku.com/changelog-items/2035). Postgres 서버가 사용하는 인증서는 Heroku 내부용이므로, **검증되지 않은(unverified)** TLS 연결을 설정해야 합니다.

다음 스니펫은 두 가지를 모두 달성하는 방법을 보여줍니다.

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    var tlsConfig: TLSConfiguration = .makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

    var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
    postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
} else {
    // ...
}
```

이 변경 사항을 커밋하는 것을 잊지 마세요.

```bash
git add .
git commit -m "configured heroku database"
```

### 데이터베이스 되돌리기

`run` 명령어를 사용해서 heroku에서 되돌리기나 다른 명령어를 실행할 수 있습니다.

데이터베이스를 되돌리려면:

```bash
heroku run App -- migrate --revert --all --yes --env production
```

마이그레이션하려면:

```bash
heroku run App -- migrate --env production
```
