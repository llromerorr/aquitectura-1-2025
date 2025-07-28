.data
    # Sección de datos para los mensajes mostrados al usuario
    msgGuideTemp:   .asciiz ">> Registros conectados al sensor de temperatura:\n\n    $s0 = SensorControl (0x2 para iniciar)\n    $s1 = SensorEstado  (1=ready, -1=error)\n    $s2 = SensorDatos   (valor temperatura)\n\n" # Mensaje guía para los registros del sensor
    msgWaitCtrl:    .asciiz "Esperando write de 0x2 en $s0 para arrancar sensor...\n" # Mensaje que solicita el inicio del sensor
    msgGotCtrl:     .asciiz "Detectado $s0 = 0x2. Ahora inicializando...\n" # Mensaje que indica que la señal de control del sensor ha sido recibida
    msgWaitState:   .asciiz "Esperando $s1 != 0 (1=ready, -1=error)....\n" # Mensaje que solicita el estado del sensor
    msgStateOK:     .asciiz "Sensor listo ($s1=1). Procediendo a lectura.\n" # Mensaje de inicialización exitosa del sensor
    msgStateErr:    .asciiz "Error de sensor ($s1=-1). Abortando.\n" # Mensaje de error del sensor durante la inicialización
    msgWaitRead:    .asciiz "Esperando que lea temperatura en $s2...\n" # Mensaje que solicita la lectura de temperatura
    msgTempOK:      .asciiz "Temp leida: " # Prefijo del mensaje para una lectura de temperatura exitosa
    msgTempErr:     .asciiz "Error lectura Temp.\n" # Mensaje de error en la lectura de temperatura
    newline:        .asciiz "\n" # Carácter de nueva línea

.text
.globl main

    # Mapeo de registros para la simulación de "hardware":
    #   $s0 = SensorControl (controla las operaciones del sensor, por ejemplo, inicio)
    #   $s1 = SensorEstado  (indica el estado del sensor: listo, error, etc.)
    #   $s2 = SensorDatos   (almacena el valor de temperatura leído)

    main:
        # Mostrar la guía de usuario para los registros del sensor
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgGuideTemp     # Cargar la dirección del mensaje guía
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Inicializar y leer el sensor
        jal  InicializarSensor     # Llamar a la función para inicializar el sensor
        jal  LeerTemperatura       # Llamar a la función para leer la temperatura del sensor

        # Fin del programa
        li   $v0, 10               # Cargar el código de servicio para salir
        syscall                    # Ejecutar la llamada al sistema para salir

    #-------------------------------------------------------------
    # InicializarSensor:
    #   Inicializa el sensor de temperatura.
    #   1) Espera a que el usuario ponga $s0 = 0x2 (señal de inicio).
    #   2) Espera a que el usuario ponga $s1 = 1 (listo) o -1 (error).
    #-------------------------------------------------------------
.globl InicializarSensor
    InicializarSensor:
        # 1) Esperar la señal de control ($s0 = 0x2)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgWaitCtrl      # Cargar la dirección del mensaje de espera de control
        syscall                    # Ejecutar la llamada al sistema para imprimir

    WaitCtrl:
        li   $t0, 0x2              # Cargar el valor de control (0x2) en $t0
        bne  $s0, $t0, WaitCtrl    # Bucle hasta que $s0 sea igual a $t0 (0x2)
        # Cuando $s0 == 0x2:
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgGotCtrl       # Cargar la dirección del mensaje que indica control detectado
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # 2) Esperar el estado del sensor ($s1 = 1 para listo, -1 para error)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgWaitState     # Cargar la dirección del mensaje de espera de estado
        syscall                    # Ejecutar la llamada al sistema para imprimir

    WaitState:
        beq  $s1, $zero, WaitState # Bucle mientras $s1 sea 0 (esperando el cambio de estado)
        # Ahora $s1 no es 0 (o 1 o -1)
        li   $t1, 1                # Cargar el valor de estado "listo" (1) en $t1
        beq  $s1, $t1, StateOK     # Si $s1 es igual a $t1 (1), saltar a StateOK

        # Si $s1 no es 1, asumimos que es -1 (error)
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgStateErr      # Cargar la dirección del mensaje de estado de error
        syscall                    # Ejecutar la llamada al sistema para imprimir
        jr   $ra                   # Volver de la función

    StateOK:
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgStateOK       # Cargar la dirección del mensaje de estado de éxito
        syscall                    # Ejecutar la llamada al sistema para imprimir
        jr   $ra                   # Volver de la función

    #-------------------------------------------------------------
    # LeerTemperatura:
    #   Lee el valor de temperatura del sensor.
    #   1) Espera a que $s1 = 1 (sensor listo).
    #   2) Lee $s2 (valor de temperatura) y lo imprime.
    #-------------------------------------------------------------
.globl LeerTemperatura
    LeerTemperatura:
        # Mostrar mensaje indicando que se está esperando la lectura de temperatura
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgWaitRead      # Cargar la dirección del mensaje de espera de lectura
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Esperar a que el sensor esté listo ($s1 = 1)
    WaitRead:
        li   $t0, 1                # Cargar el valor de estado "listo" (1) en $t0
        bne  $s1, $t0, WaitRead    # Bucle mientras $s1 no sea igual a $t0 (1)

        # Leer datos (temperatura) de $s2
        # Nota: 'move $v0, $s2' aquí es una colocación inusual, ya que $v0 se usa típicamente para códigos de syscall o valores de retorno.
        # No afecta a la syscall para imprimir cadena/entero más adelante, pero vale la pena notarlo.
        move $v0, $s2              # Mover el valor de $s2 (SensorDatos) a $v0 (posible valor de retorno o almacenamiento temporal)

        # Imprimir el mensaje "Temp leida: "
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgTempOK        # Cargar la dirección del mensaje "Temp leida:"
        syscall                    # Ejecutar la llamada al sistema para imprimir

        # Imprimir el valor de temperatura leído
        move $a0, $s2              # Mover el valor de $s2 (SensorDatos) a $a0 para imprimir
        li   $v0, 1                # Cargar el código de servicio para imprimir entero
        syscall                    # Ejecutar la llamada al sistema para imprimir el entero

        jr   $ra                   # Volver de la función

    ReadErr:
        li   $v0, 4                # Cargar el código de servicio para imprimir cadena
        la   $a0, msgTempErr       # Cargar la dirección del mensaje de error de lectura de temperatura
        syscall                    # Ejecutar la llamada al sistema para imprimir
        jr   $ra                   # Volver de la función