# GeoPonto

Aplicativo mobile desenvolvido em Flutter para gestão de frequência, registro de ponto com geolocalização e envio de ocorrências (atestados, justificativas de faltas e esquecimentos).

## Funcionalidades
* **Autenticação:** Login seguro para colaboradores.
* **Registro de Ponto:** Marcação de ponto validada por geolocalização e raio de distância da empresa.
* **Histórico Mensal:** Calendário dinâmico com feedback visual (verde, laranja, vermelho) sobre a carga horária trabalhada e pendências.
* **Ocorrências:** Envio de justificativas e atestados diretamente pelo aplicativo.
* **Modo Escuro:** Suporte nativo a *Dark Mode* integrado ao tema do sistema operacional.

## Tecnologias Utilizadas
* **Frontend:** Flutter & Dart
* **Backend/Database:** Supabase (Autenticação e Banco de Dados PostgreSQL)
* **Geolocalização:** Pacote `geolocator`
* **Gerenciamento de Variáveis:** Pacote `flutter_dotenv`

## Como baixar e testar o App (Sem precisar compilar)
Se você deseja apenas testar o aplicativo em um dispositivo Android:
1. Acesse a aba [Releases](../../releases) deste repositório.
2. Baixe o arquivo `.apk` da versão mais recente.
3. Abra o arquivo no seu smartphone Android. *Nota: Pode ser necessário autorizar a instalação de aplicativos de fontes desconhecidas nas configurações do seu navegador.*
4. Instale e teste!

---

## Como rodar o projeto localmente (Para Desenvolvedores)

### Pré-requisitos
* Ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
* Dispositivo físico Android/iOS ou Emulador configurado.
* E acesso às nossas chaves do [Supabase](https://supabase.com/) para a criação do arquivo .env

### Instalação

1. **Clone o repositório:**
   ```bash
   git clone [https://github.com/SEU_USUARIO/geoponto.git](https://github.com/SEU_USUARIO/geoponto.git)
   cd geoponto
