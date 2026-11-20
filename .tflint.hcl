# Configuración de TFLint para todo el repo.
# Uso desde la raíz:  tflint --recursive

config {
  # Revisa también los módulos llamados desde cada entorno.
  call_module_type = "local"
}

# Ruleset de Terraform (viene incluido en TFLint, no se descarga nada).
# El preset "all" activa todas las reglas: variables y outputs documentados
# y tipados, convención de nombres, estructura estándar de módulo, etc.
plugin "terraform" {
  enabled = true
  preset  = "all"
}
