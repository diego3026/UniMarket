// Términos y condiciones de UniMarket. Es el mismo texto de la página web
// (terminos.html): si cambias uno, cambia el otro.
//
// Las cifras de comisión y de cancelaciones deben coincidir con las variables
// del backend (COMMISSION_* y CANCEL_*).

class TermsSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  const TermsSection(
    this.title, {
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const termsUpdated = '21 de noviembre de 2026';

const termsSections = <TermsSection>[
  TermsSection(
    '1. Qué es UniMarket',
    paragraphs: [
      'UniMarket es una plataforma que conecta a compradores de la comunidad de la Universidad del Magdalena con '
          'emprendimientos de estudiantes. UniMarket no fabrica ni vende los productos: cada emprendedor es '
          'responsable de lo que ofrece, de su calidad, precio, entrega y de cumplir las normas que le apliquen.',
    ],
  ),
  TermsSection(
    '2. Tu cuenta',
    paragraphs: [
      'Debes dar información real, mantener tu contraseña en secreto y avisarnos si alguien usa tu cuenta sin '
          'permiso. Podemos suspender cuentas que incumplan estos términos o que se usen para fraude.',
    ],
  ),
  TermsSection(
    '3. Pedidos y pagos',
    bullets: [
      'Los precios, descuentos y totales que muestra la app son los que se cobran.',
      'Con efectivo pagas al recoger o recibir. Con Bre-B o Nequi transfieres directamente al emprendedor y él '
          'confirma el pago; UniMarket no recibe ni guarda ese dinero.',
      'Puedes cancelar un pedido mientras la tienda no haya empezado a prepararlo.',
      'Los reclamos sobre un producto se resuelven primero con el emprendedor; si no hay solución, escríbenos y '
          'mediaremos.',
    ],
  ),
  TermsSection(
    '4. Emprendedores',
    paragraphs: [
      'Las tiendas pasan por una revisión antes de publicarse. El emprendedor se compromete a publicar información '
          'veraz, cumplir los pedidos que acepta, no vender productos prohibidos por la ley o por la universidad y '
          'manejar con cuidado los datos de sus clientes, usándolos solo para atender el pedido.',
    ],
  ),
  TermsSection(
    '5. Comisión de UniMarket',
    paragraphs: [
      'UniMarket cobra a los emprendedores una comisión sobre las ventas hechas a través de la app. Los clientes '
          'no pagan comisión.',
    ],
    bullets: [
      'Primeros 2 meses gratis: los pedidos que reciba la tienda durante los primeros 60 días contados desde que '
          'UniMarket la aprueba tienen 0 % de comisión.',
      'Después, la comisión es mensual y escalonada: 1 % sobre las ventas del mes hasta \$500.000 y 2 % solo sobre '
          'la parte que supere \$500.000. Ejemplo: con ventas de \$700.000 en el mes, la comisión es \$5.000 '
          '(1 % de \$500.000) + \$4.000 (2 % de \$200.000) = \$9.000.',
      'Base de cálculo: el valor que pagó el cliente por los productos (después de descuentos y cupones, sin el '
          'domicilio) de los pedidos entregados en el mes. También cuentan los pedidos cancelados por la tienda que '
          'el cliente indicó haber recibido o que UniMarket confirmó como venta (sección 6).',
      'El emprendedor ve en la app, en "Comisiones", el detalle de cada mes: pedidos incluidos, ventas exentas y '
          'valor a pagar.',
      'La comisión de cada mes se paga dentro de los 10 días calendario siguientes al cierre del mes, por el medio '
          'que UniMarket indique. Si no se paga a tiempo, la tienda puede ser suspendida hasta ponerse al día.',
      'UniMarket avisará cualquier cambio en las tarifas con al menos 30 días de anticipación.',
    ],
  ),
  TermsSection(
    '6. Cancelaciones y control de ventas',
    paragraphs: [
      'Para que la comisión sea justa para todos, UniMarket verifica las cancelaciones con estas reglas:',
    ],
    bullets: [
      'La tienda solo puede cancelar pedidos "pendientes" o "en preparación", indicando el motivo. Cuando el pedido '
          'está "listo" o "en camino" ya no puede cancelarlo.',
      'Si la tienda cancela un pedido cuyo pago el cliente ya reportó o la tienda ya confirmó, debe devolver el '
          '100 % del dinero al cliente en un plazo máximo de 2 días hábiles. El pedido queda marcado como "pagado y '
          'cancelado" y UniMarket lo revisa.',
      'Cuando la tienda cancela, la app le pregunta al cliente si de todas formas recibió el pedido. El cliente '
          'tiene 7 días para responder. Si responde que sí, se abre una revisión y el pedido cuenta como venta para '
          'la comisión mientras UniMarket no la descarte. Ambas partes pueden aportar pruebas (mensajes, '
          'comprobantes de pago o de devolución).',
      'UniMarket mide, para cada tienda y en periodos de 30 días: el porcentaje de pedidos cancelados, las '
          'cancelaciones después de aceptar el pedido, las cancelaciones con pago reportado y las cancelaciones que '
          'el cliente contradice. Si una tienda cancela más del 15 % de sus pedidos (con al menos 5 pedidos en el '
          'periodo) o tiene cancelaciones con pago o contradichas, su cuenta pasa a revisión.',
      'Cancelar en la app pedidos que sí se vendieron, o llevar a los clientes de la app a comprar por fuera de '
          'ella para no pagar la comisión, se considera fraude. En ese caso UniMarket puede: cobrar la comisión de '
          'esas ventas, retirar el beneficio de 0 %, bajar la visibilidad de la tienda y suspenderla o cerrarla si '
          'se repite.',
      'Los clientes deben responder con la verdad. Las respuestas falsas para perjudicar a una tienda también son '
          'motivo de suspensión.',
    ],
  ),
  TermsSection(
    '7. Contenido',
    paragraphs: [
      'Eres responsable de las fotos, descripciones y reseñas que publicas. No se permite contenido ofensivo, '
          'engañoso o que infrinja derechos de terceros; podemos ocultarlo sin aviso.',
    ],
  ),
  TermsSection(
    '8. Responsabilidad',
    paragraphs: [
      'Trabajamos para que el servicio funcione bien, pero puede tener interrupciones. UniMarket no responde por los '
          'productos vendidos por los emprendedores ni por acuerdos hechos por fuera de la app.',
    ],
  ),
  TermsSection(
    '9. Datos personales',
    paragraphs: [
      'El tratamiento de tus datos se rige por nuestra Política de privacidad, disponible en '
          'diego3026.github.io/UniMarket/privacidad.html.',
    ],
  ),
  TermsSection(
    '10. Ley aplicable y contacto',
    paragraphs: [
      'Estos términos se rigen por las leyes de Colombia. Contacto: unimarketdev@gmail.com.',
    ],
  ),
];
