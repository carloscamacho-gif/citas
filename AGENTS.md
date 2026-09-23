# AGENTS.md — Workspace `citas`

Generado por el agente orquestador cross-repo siguiendo `prompts/agents/PROMPT_AGENT_ORQUESTADOR.md`. Léelo antes de tocar cualquier archivo de este workspace.

## Qué es este workspace

`citas/` es un laboratorio de formación con **dos repositorios Git independientes**:

- `citas-api`: Java 21 + Spring Boot 3.5.x + Maven + arquitectura hexagonal + MySQL/Flyway. Consulta su README y, cuando exista, su propio `AGENTS.md`.
- `citas-web`: frontend TypeScript (React o Angular, decidido por el estudiante vía Stitch + Google AI Studio). No hay Express/BFF; consume `citas-api` directo por REST.

La carpeta raíz **no es un tercer repositorio**: solo orquesta y da visibilidad cross-repo. No inicialices Git aquí.

## Reglas que gobiernan cualquier agente en este workspace

1. No mezclar responsabilidades: lógica de negocio va en `citas-api`; UI va en `citas-web`.
2. El frontend consume Spring Boot directamente por REST; nunca se agrega una capa BFF/Express.
3. No inventar requerimientos fuera de `PRD.md` y las HU aprobadas en `citas-api/docs/wiki/scrum/`.
4. Antes de un cambio cross-repo, producir un plan explícito enumerando qué repos/archivos se van a tocar.
5. `main` = estable, `develop` = trabajo, en cada repo por separado. No forzar merge por sesión.
6. Nunca usar datos reales de FCV salvo la información pública ya incluida en el PRD (nombres de sedes y especialidades). Todo lo demás (pacientes, profesionales, credenciales, agendas, citas) es sintético.
7. Nunca abrir, imprimir ni reproducir secretos de `.env`.
8. Los workflows n8n se versionan como JSON en `citas-api/automations/n8n/`.

## Skills y su alcance de escritura

- **`scrum-spec-orchestrator`**: solo puede crear/editar archivos bajo `citas-api/docs/wiki/scrum/**`. Nunca implementa código, nunca ejecuta comandos que alteren el repositorio (`git add`/`commit`/`checkout`/etc.), nunca corrige código para forzar el cierre de una HU. Ver `skills/scrum-spec-orchestrator/`.
- **`stitch-design-to-frontend`**: gobierna el ciclo Stitch → aprobación explícita del diseño → handoff a Google AI Studio → reconciliación en `citas-web`. No inventa comportamiento de backend. Ver `skills/stitch-design-to-frontend/`.

## Coordinación de trabajo

- Tarea solo de backend → trabajar/delegar dentro de `citas-api`.
- Tarea solo de frontend → trabajar/delegar dentro de `citas-web`.
- Cambio de contrato REST → coordinar ambos repos y exigir evidencia en ambos lados (ver DoD de cada HU, que exige documentar el contrato — RF-20).
- La unidad primaria de alcance es la HU aprobada en `citas-api/docs/wiki/scrum/historias-de-usuario/`; no se implementa nada que no esté ahí.

## LLM Wiki — memoria global del proyecto

Vive en `citas-api/docs/wiki/llm-wiki/` con el patrón RAW / WIKI / SCHEMA (fuente: gist de Karpathy referenciado en `prompts/agents/PROMPT_AGENT_ORQUESTADOR.md`):

- `raw/`: fuentes curadas e inmutables (PRD aprobado, decisiones, contratos, notas validadas). Se lee, no se reescribe durante el ingest.
- `wiki/`: páginas Markdown mantenidas por el agente — `index.md` (catálogo, leer primero), `log.md` (registro cronológico append-only), `dominio.md`, `arquitectura.md`, `decisiones.md`, `riesgos.md`.
- `schema/`: convenciones y workflows de la wiki.

Operaciones: INGEST (integrar una fuente aprobada en las páginas existentes, actualizar índice y log), QUERY (index → páginas → verificar contra código/specs, separando evidencia de inferencia), LEARN (extraer solo conocimiento durable tras una interacción sustancial, clasificado como HECHO/DECISIÓN/PREFERENCIA/PREGUNTA ABIERTA), LINT (detectar contradicciones, claims obsoletos, duplicados, enlaces rotos, contenido sensible).

La wiki nunca debe convertirse en transcript ni almacenar passwords, tokens, credenciales o PII más allá de lo estrictamente necesario.

## Orden de lectura recomendado para cualquier agente nuevo

1. `README.md`
2. `PRD.md`
3. `RESTRICCIONES_TECNICAS.md`
4. `database/REQUISITOS_NORMALIZACION_3FN.md`
5. `citas-api/README.md`
6. `citas-web/README.md`
7. `AGENTS.md` de cada repo, cuando existan
8. `citas-api/docs/wiki/llm-wiki/wiki/index.md`
9. `citas-api/docs/wiki/scrum/README.md`
