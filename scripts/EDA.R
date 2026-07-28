#===========================================================#
# PROYECTO FINAL - ANALISIS EXPLORATORIO DE DATOS           #
# Base: Multas administrativas activas de Ate               #
#===========================================================#

rm(list = ls())

library(readr)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(patchwork)

# 1. Importación ---------------------------------------------------------
# Se leen todas las columnas como texto para conservar los códigos con 0.
multas <- read_csv(
  "data/multas_ate_original.csv",
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
)

# Revisión inicial
multas %>% dim()
multas %>% glimpse()
multas %>% is.na() %>% colSums()

# 2. Limpieza y preparación ---------------------------------------------
multas_limpias <- multas %>%
  rename(
    codigo = CODIGO,
    anio_multa = ANIOMULTA,
    numero_multa = NUMMUL,
    zona = ZONA,
    fecha_multa = FECHAMULTA,
    fecha_sistema = FECHASISTEMA,
    estado = ESTADO,
    fecha_proyeccion = FECHAPROYECCION,
    codigo_giro = CODIGODEGIRO,
    giro = GIRO,
    codigo_multa = CODIGOMULTA,
    descripcion = DESCRIPCION,
    monto = MONTO,
    interes = INTERES,
    gastos = GASTOS,
    costas = COSTAS,
    descuento = DESCUENTO,
    total = TOTAL,
    departamento = DEPARTAMENTO,
    provincia = PROVINCIA,
    distrito = DISTRITO,
    ubigeo = UBIGEO,
    fecha_corte = FECHA_CORTE
  ) %>%
  mutate(
    across(everything(), ~na_if(trimws(.x), "")),
    anio_multa = as.integer(anio_multa),
    fecha_multa = ymd(fecha_multa),
    fecha_sistema = ymd(fecha_sistema),
    fecha_proyeccion = ymd(fecha_proyeccion),
    fecha_corte = ymd(fecha_corte),
    across(
      c(monto, interes, gastos, costas, descuento, total),
      as.numeric
    ),
    across(
      c(interes, gastos, costas, descuento),
      ~replace_na(.x, 0)
    ),
    deuda_bruta = monto + interes + gastos + costas,
    tiene_descuento = ifelse(descuento > 0, "Sí", "No")
  ) %>%
  distinct()

# La base limpia se guarda en formato propio de R.
saveRDS(multas_limpias, "data/multas_ate_limpia.rds")

# Revisión de la base limpia
multas_limpias %>% dim()
multas_limpias %>% glimpse()
multas_limpias %>% is.na() %>% colSums()

# 3. Estadísticas descriptivas ------------------------------------------

# Resumen de la variable total
estadisticas_total <- multas_limpias %>%
  summarise(
    observaciones = n(),
    promedio = mean(total, na.rm = TRUE),
    mediana = median(total, na.rm = TRUE),
    desviacion_estandar = sd(total, na.rm = TRUE),
    minimo = min(total, na.rm = TRUE),
    maximo = max(total, na.rm = TRUE),
    monto_acumulado = sum(total, na.rm = TRUE)
  )

estadisticas_total

# Frecuencias por año
tabla_anio <- multas_limpias %>%
  group_by(anio_multa) %>%
  summarise(cantidad = n()) %>%
  arrange(anio_multa)

tabla_anio

# Frecuencias por estado
tabla_estado <- multas_limpias %>%
  group_by(estado) %>%
  summarise(
    cantidad = n(),
    monto_total = sum(total, na.rm = TRUE)
  ) %>%
  arrange(desc(cantidad))

tabla_estado

# Principales giros según cantidad de multas
tabla_giro <- multas_limpias %>%
  group_by(giro) %>%
  summarise(
    cantidad = n(),
    monto_total = sum(total, na.rm = TRUE)
  ) %>%
  arrange(desc(cantidad))

tabla_giro %>% head(10)

# 4. Visualización -------------------------------------------------------

# Gráfico 1: cantidad de multas por año
grafico_1 <- tabla_anio %>%
  ggplot(aes(x = anio_multa, y = cantidad)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq(1999, 2024, 2)) +
  labs(
    title = "Multas administrativas activas según año de emisión",
    subtitle = "Municipalidad Distrital de Ate | Fecha de corte: 19/06/2024",
    x = "Año de la multa",
    y = "Cantidad de registros",
    caption = "Fuente: Plataforma Nacional de Datos Abiertos - Municipalidad Distrital de Ate"
  ) +
  theme_minimal()

# Gráfico 2: distribución del monto total
grafico_2 <- multas_limpias %>%
  filter(total > 0) %>%
  ggplot(aes(x = log10(total))) +
  geom_histogram(bins = 35) +
  labs(
    title = "Distribución del monto total de las multas activas",
    subtitle = "Se utiliza log10 para observar mejor la concentración de los montos",
    x = "log10 del total de la multa (S/)",
    y = "Cantidad de registros",
    caption = "Fuente: Plataforma Nacional de Datos Abiertos - Municipalidad Distrital de Ate"
  ) +
  theme_minimal()

# Guardado de gráficos individuales
ggsave(
  "figures/grafico_multas_anio.png",
  grafico_1,
  width = 11,
  height = 6.5,
  dpi = 300
)

ggsave(
  "figures/grafico_distribucion_total.png",
  grafico_2,
  width = 11,
  height = 6.5,
  dpi = 300
)

# Collage solicitado para GitHub
collage <- grafico_1 / grafico_2 +
  plot_annotation(
    title = "Análisis exploratorio de las multas administrativas activas de Ate"
  )

ggsave(
  "figures/collage_graficos.png",
  collage,
  width = 12,
  height = 12,
  dpi = 300
)
