CREATE TABLE public.usuarios (
  id uuid NOT NULL,
  empresa_id uuid,
  setor_id uuid,
  nome character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  tipo_usuario USER-DEFINED NOT NULL,
  ativo boolean NOT NULL DEFAULT true,
  primeiro_acesso boolean NOT NULL DEFAULT true,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  dispositivo_usuario text,
  cpf character varying,
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT fk_usuarios_empresa FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),
  CONSTRAINT fk_usuarios_setor FOREIGN KEY (setor_id) REFERENCES public.setores(id)
);
CREATE TABLE public.empresas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  admin_id uuid UNIQUE,
  nome character varying NOT NULL,
  cnpj character varying UNIQUE,
  latitude_ponto double precision,
  longitude_ponto double precision,
  raio_permitido_m integer NOT NULL DEFAULT 50,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT empresas_pkey PRIMARY KEY (id),
  CONSTRAINT fk_empresas_admin FOREIGN KEY (admin_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.setores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  empresa_id uuid NOT NULL,
  gestor_id uuid,
  nome character varying NOT NULL,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT setores_pkey PRIMARY KEY (id),
  CONSTRAINT fk_setores_empresa FOREIGN KEY (empresa_id) REFERENCES public.empresas(id),
  CONSTRAINT fk_setores_gestor FOREIGN KEY (gestor_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.jornadas_trabalho (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  carga_horaria_sem integer NOT NULL CHECK (carga_horaria_sem > 0),
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT jornadas_trabalho_pkey PRIMARY KEY (id)
);
CREATE TABLE public.jornadas_usuarios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  jornada_id uuid NOT NULL,
  data_inicio_vigencia date NOT NULL,
  data_fim_vigencia date,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT jornadas_usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT fk_jornadas_usuarios_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT fk_jornadas_usuarios_jornada FOREIGN KEY (jornada_id) REFERENCES public.jornadas_trabalho(id)
);
CREATE TABLE public.registros_ponto (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  tipo_registro_ponto USER-DEFINED NOT NULL,
  latitude_disp double precision NOT NULL,
  longitude_disp double precision NOT NULL,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT registros_ponto_pkey PRIMARY KEY (id),
  CONSTRAINT fk_registros_ponto_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.ocorrencias (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  gestor_id uuid NOT NULL,
  data_inicio date NOT NULL,
  data_fim date,
  minutos_abonados integer,
  tipo_ocorrencia USER-DEFINED NOT NULL,
  justificativa text NOT NULL,
  horario_proposto time without time zone,
  aprovada boolean NOT NULL DEFAULT false,
  observacao_gestor text,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT ocorrencias_pkey PRIMARY KEY (id),
  CONSTRAINT fk_ocorrencias_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT fk_ocorrencias_gestor FOREIGN KEY (gestor_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.fechamentos_mensais (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  mes_referencia date NOT NULL,
  minutos_previstos integer NOT NULL,
  minutos_trabalhados integer NOT NULL,
  minutos_abonados integer NOT NULL,
  saldo_minutos integer NOT NULL,
  fechada boolean NOT NULL DEFAULT false,
  criado_em timestamp with time zone NOT NULL DEFAULT now(),
  atualizado_em timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT fechamentos_mensais_pkey PRIMARY KEY (id),
  CONSTRAINT fk_fechamentos_mensais_usuario FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);

