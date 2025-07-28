.data
    # Sección de datos para los mensajes mostrados al usuario
    msgGuideTens: .asciiz ">> Registros conectados al modulo de tension arterial:\n\n    $s0 = TensionControl  [1/0] (iniciar medicion / standby)\n    $s1 = TensionEstado   [1/0] (medicion lista / midiendo)\n    $s2 = TensionSistol   (valor sistólica)\n    $s3 = TensionDiastol  (valor diastólica)\n\n" # Mensaje guía para los registros del módulo de presión arterial
    msgStart:     .asciiz "Iniciando modulo de tensión arterial...\n" # Mensaje para iniciar el módulo
    msgWaitCtrl:  .asciiz "Esperando write de 1 en $s0 para arrancar medida...\n" # Mensaje que solicita el inicio de la medición
    msgGotCtrl:   .asciiz "Detectado $s0 = 1. Midiendo...\n" # Mensaje que indica que la señal de control ha sido recibida y la medición está en curso
    msgWaitState: .asciiz "Esperando $s1 = 1 (ready)....\n" # Mensaje que solicita el estado de la medición
    msgStateOK:   .asciiz "Listo ($s1=1). Obteniendo resultados.\n" # Mensaje de finalización exitosa de la medición
    msgResult:    .asciiz "Tensión = " # Prefijo del mensaje para el resultado de la presión arterial
    msgSlash:     .asciiz " / " # Separador para los valores sistólico y diastólico
    newline:      .asciiz "\n" # Carácter de nueva línea

.text
.globl main

# Mapeo de registros para la simulación de "hardware" del módulo de presión arterial:
#   $s0 = TensionControl  (1 para iniciar la medición, 0 para modo de espera)
#   $s1 = TensionEstado   (1 si la medición está lista, 0 si está midiendo)
#   $s2 = TensionSistol   (almacena el valor de la presión arterial sistólica)
#   $s3 = TensionDiastol  (almacena el valor de la presión arterial diastólica)

    main:
        # Mostrar la guía de usuario para los registros del módulo de presión arterial
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgGuideTens     # Cargar la dirección del mensaje guía
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Mostrar mensaje de inicio
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgStart         # Cargar la dirección del mensaje de inicio
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Llamar a la función controladora de la tensión arterial
        jal  controlador_tension   # Saltar y enlazar a la función controladora

        # Imprimir el mensaje "Tensión = "
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgResult        # Cargar la dirección del mensaje de resultado
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Imprimir el valor sistólico (desde $s2, que fue movido a $v0 por controlador_tension)
        move $a0, $s2              # Mover el valor sistólico de $s2 a $a0 para imprimir. (Nota: $v0 también contiene este valor de la llamada jal)
        li   $v0, 1                # Cargar el código de servicio para imprimir entero
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Imprimir el separador " / "
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgSlash         # Cargar la dirección del mensaje de barra
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Imprimir el valor diastólico (desde $s3, que fue movido a $v1 por controlador_tension)
        # Aquí, $v1 se usa ya que contiene el valor diastólico devuelto por la función.
        # Alternativamente, $s3 también podría usarse directamente si su valor se conserva.
        move $a0, $v1              # Mover el valor diastólico de $v1 a $a0 para imprimir
        li   $v0, 1                # Cargar el código de servicio para imprimir entero
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Imprimir una nueva línea y salir del programa
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, newline          # Cargar la dirección del carácter de nueva línea
        syscall                    # Ejecutar la llamada al sistema para imprimir
        li   $v0, 10               # Cargar el código de servicio para salir
        syscall                    # Ejecutar la llamada al sistema para salir

    #-------------------------------------------------------------
    # controlador_tension:
    #   Controla el proceso de medición de la presión arterial.
    #   1) Espera a que el usuario ponga $s0 = 1 (iniciar medición).
    #   2) Espera a que el usuario ponga $s1 = 1 (medición lista).
    #   3) Devuelve el valor sistólico ($s2) en $v0 y el valor diastólico ($s3) en $v1.
    #-------------------------------------------------------------
.globl controlador_tension
    controlador_tension:
        # 1) Esperar la señal de control ($s0 = 1) para iniciar la medición
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgWaitCtrl      # Cargar la dirección del mensaje de espera de control
        syscall                    # Ejecutar la llamada al sistema para imprimir

    WaitCtrlT:
        li   $t0, 1                # Cargar el valor de control (1) en $t0
        bne  $s0, $t0, WaitCtrlT   # Bucle hasta que $s0 sea igual a $t0 (1)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgGotCtrl       # Cargar la dirección del mensaje que indica control detectado y midiendo
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # 2) Esperar el estado de la medición ($s1 = 1 para lista)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgWaitState     # Cargar la dirección del mensaje de espera de estado
        syscall                    # Ejecutar la llamada al sistema para imprimir

    WaitStateT:
        li   $t1, 1                # Cargar el valor de estado "listo" (1) en $t1
        bne  $s1, $t1, WaitStateT  # Bucle mientras $s1 no sea igual a $t1 (1)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgStateOK       # Cargar la dirección del mensaje de estado de éxito
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # 3) Leer y devolver los valores sistólico y diastólico
        move $v0, $s2              # Mover el valor sistólico de $s2 a $v0 (valor de retorno)
        move $v1, $s3              # Mover el valor diastólico de $s3 a $v1 (valor de retorno)
        jr   $ra                   # Volver de la función