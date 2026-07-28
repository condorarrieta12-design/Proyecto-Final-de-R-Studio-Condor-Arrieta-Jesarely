#===========================================================#
# PARTE 2 - ANALISIS FINAL                                  #
#===========================================================#

rm(list = ls())

library(dplyr)
library(ggplot2)
library(patchwork)
library(scales)

# Se utiliza directamente la base limpia creada en el EDA.
multas_limpias <- readRDS("data/multas_ate_limpia.rds")

# Pregunta de análisis:
# ¿Los giros con mayor cantidad de multas son también los que
# concentran el mayor monto total acumulado?

# 1. Resumen por giro ----------------------------------------------------
resumen_giro <- multas_limpias %>%
  group_by(giro) %>%
  summarise(
    cantidad_multas = n(),
    monto_total = sum(total, na.rm = TRUE),
    monto_promedio = mean(total, na.rm = TRUE),
    monto_mediano = median(total, na.rm = TRUE)
  ) %>%
  arrange(desc(monto_total))

resumen_giro %>% head(10)

# 2. Indicadores principales --------------------------------------------
top_cantidad <- resumen_giro %>%
  slice_max(cantidad_multas, n = 10, with_ties = FALSE)

top_monto <- resumen_giro %>%
  slice_max(monto_total, n = 10, with_ties = FALSE)

participacion_top10 <- top_monto %>%
  summarise(
    participacion = sum(monto_total) /
      sum(multas_limpias$total, na.rm = TRUE) * 100
  )

participacion_top10

# 3. Gráfico comparativo -------------------------------------------------
grafico_cantidad <- top_cantidad %>%
  ggplot(aes(x = reorder(giro, cantidad_multas), y = cantidad_multas)) +
  geom_col() +
  geom_text(
    aes(label = comma(cantidad_multas)),
    hjust = -0.1,
    size = 3
  ) +
  coord_flip() +
  expand_limits(y = max(top_cantidad$cantidad_multas) * 1.15) +
  labs(
    title = "Giros con mayor cantidad de multas activas",
    x = "",
    y = "Cantidad de multas"
  ) +
  theme_minimal()

grafico_monto <- top_monto %>%
  mutate(monto_millones = monto_total / 1000000) %>%
  ggplot(aes(x = reorder(giro, monto_millones), y = monto_millones)) +
  geom_col() +
  geom_text(
    aes(label = paste0("S/ ", round(monto_millones, 1), " M")),
    hjust = -0.1,
    size = 3
  ) +
  coord_flip() +
  expand_limits(y = max(top_monto$monto_total / 1000000) * 1.20) +
  labs(
    title = "Giros con mayor monto total acumulado",
    x = "",
    y = "Monto acumulado (millones de S/)"
  ) +
  theme_minimal()

grafico_final <- grafico_cantidad / grafico_monto +
  plot_annotation(
    title = "Cantidad de multas y monto acumulado por giro económico",
    subtitle = "Los giros con más registros no siempre generan la mayor deuda",
    caption = "Fuente: Plataforma Nacional de Datos Abiertos - Municipalidad Distrital de Ate"
  )

ggsave(
  "figures/grafico_analisis_final.png",
  grafico_final,
  width = 12,
  height = 13,
  dpi = 300
)

print(grafico_final)

# 4. Resultados para las conclusiones -----------------------------------
giro_mas_multas <- top_cantidad %>%
  arrange(desc(cantidad_multas)) %>%
  slice(1)

giro_mayor_monto <- top_monto %>%
  arrange(desc(monto_total)) %>%
  slice(1)

cat(
  "El giro con más multas es:", giro_mas_multas$giro,
  "con", giro_mas_multas$cantidad_multas, "registros.\n"
)

cat(
  "El giro con mayor monto total es:", giro_mayor_monto$giro,
  "con S/", round(giro_mayor_monto$monto_total, 2), ".\n"
)

cat(
  "Los 10 giros con mayor monto representan",
  round(participacion_top10$participacion, 2),
  "% del monto total de la base.\n"
)
