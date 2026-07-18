# Deploy — Gerenciamento de Quadra

Deploy da stack completa (PostgreSQL + API .NET + Flutter Web) via Docker Compose.
Pensado para conviver com outros sites já hospedados no mesmo VPS **sem afetá-los**:
a stack sobe isolada e só o container `web` é publicado numa porta local, que o
nginx do host encaminha para um **subdomínio próprio**.

## Arquitetura

```
Internet ──HTTPS──> nginx do host (subdomínio) ──> :8090 (container web / nginx)
                                                      ├── serve o Flutter Web
                                                      └── /api → container api (:8080)
                                                                    └── container db (PostgreSQL)
```

O container `web` faz o proxy de `/api` para a API na mesma origem — **sem CORS** e
sem expor a API diretamente à internet. O Postgres fica só na rede interna do compose.

## Pré-requisitos no VPS

- Docker + Docker Compose plugin
- nginx no host (reverse proxy) + certbot para TLS
- DNS do subdomínio (ex.: `quadra.grupof2.tech`) apontando para o IP do VPS

## Passo a passo

```bash
# 1. Enviar o código para o servidor (git clone/pull ou rsync). Ex.: /opt/quadra
cd /opt/quadra/deploy

# 2. Configurar segredos
cp .env.example .env
nano .env            # defina POSTGRES_PASSWORD e JWT_KEY (openssl rand -base64 48)

# 3. Subir a stack (build + start)
docker compose -f docker-compose.prod.yml --env-file .env up -d --build

# 4. Verificar
docker compose -f docker-compose.prod.yml ps
curl -s http://127.0.0.1:8090/api/quadras   # deve responder JSON

# 5. Reverse proxy do host (subdomínio) — ver nginx-host-quadra.conf.example
sudo cp nginx-host-quadra.conf.example /etc/nginx/sites-available/quadra
sudo ln -s /etc/nginx/sites-available/quadra /etc/nginx/sites-enabled/quadra
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d quadra.grupof2.tech
```

O firewall (ufw) **não precisa** de novas regras: o tráfego externo continua entrando
só por 80/443; a porta 8090 é acessada apenas pelo nginx local (127.0.0.1).

## Atualizações

```bash
cd /opt/quadra && git pull
cd deploy && docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

Migrações do banco rodam automaticamente na subida da API (`DbSeeder`).

## Segurança em produção

- Troque `JWT_KEY` e `POSTGRES_PASSWORD` por valores fortes e aleatórios.
- **Troque as senhas dos usuários seed** (`admin@quadra.local` / `Admin@123`) no primeiro acesso.
- O `.env` real nunca deve ser versionado (já ignorado no `.gitignore`).
