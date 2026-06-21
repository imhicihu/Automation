### Cómo colaborar
1. Haz un bifurcación del repositorio `nombre_del_proyecto`
2. Clona el repositorio `nombre_del_proyecto` en tu equipo local
  ```
  git clone git@github.com:<TU_NOMBRE_DE_USUARIO_EN_GITHUB>/www.git # SSH
  git clone https://github.com/<TU_NOMBRE_DE_USUARIO_EN_GITHUB>/www.git # HTTPS
  gh repo clone <TU_NOMBRE_DE_USUARIO_EN_GITHUB>/www # GitHub CLI
  ```
3. Cambia al directorio del repositorio clonado
  ```
  cd nombre_del_proyecto
  ```
4. Crea una rama para tu contribución
  ```
  git checkout -b <NOMBRE_DE_LA_RAMIFICACIÓN>
  ```
5. Inicia el entorno de desarrollo
   ```
   npm install # o tu gestor de paquetes favorito: brew, bun
   npm run dev
   ```
6. Realiza tus cambios
7. Una vez que hayas terminado, confirma tus cambios
   ```
   git add .
   git commit -m "Tu mensaje de confirmación"
   ```
