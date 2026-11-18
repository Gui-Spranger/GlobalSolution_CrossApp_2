# Radar Territorial

**Painel de Inteligência Territorial**: Global Solution 2026.2, Cross-Platform Application Development (2CC)

App mobile em **Flutter**, com tema escuro, que ajuda um gestor público a antecipar problemas de água, energia, resíduos, demanda por serviços e clima em um bairro, município ou comunidade rural. O app **mostra dados, gera alertas e sugere respostas, mas não toma decisões**: quem decide é o gestor.

## Integrantes

| Nome completo | RM |
|---|---|
| GUILHERME SPRANGER DOS SANTOS | RM564059 |
| SAMUEL DE SOUZA JORGE | RM558966 |

## Funcionalidades

1. **Dashboard com gráficos e indicadores**: cartões de água, energia, resíduos e chamados (média de 7 dias, % da capacidade, variação semanal), gráfico de barras com 14 dias de histórico, 7 dias de projeção e a linha de capacidade, além da previsão do tempo.
2. **Alertas preditivos**: cada alerta traz **justificativa** (os números que levaram a ele), **nível de confiança** (Alta/Média/Baixa com %) e **limitações**.
3. **Apoio à decisão sem automação**: o app só sugere opções. O gestor registra a própria decisão (adotar, monitorar ou descartar) num formulário. Decisões de **alto impacto** exigem uma confirmação extra e lembram que a execução depende da instância competente.

## Requisitos técnicos

| Requisito | Como foi feito | Arquivo |
|---|---|---|
| Flutter | Projeto todo | `lib/` |
| Navegação entre telas | 3 abas (Painel, Alertas, Decisões) + telas de detalhe do alerta, formulários e ajustes | `screens/home_screen.dart` |
| Gerenciamento de estado | `provider` + `ChangeNotifier` | `app_state.dart` |
| Consumo de API | Open-Meteo com `http` (clima real) | `services.dart` |
| Persistência | `shared_preferences`: decisões, regiões cadastradas, região escolhida, tamanho do texto e último clima (para uso sem internet) | `services.dart` |
| Formulários com validação | **Cadastro de região**: nome obrigatório e sem repetição, população inteira e positiva, latitude e longitude dentro dos limites. **Registro de decisão**: campos obrigatórios, tamanho mínimo, bloqueio de dados pessoais, confirmações obrigatórias | `screens/region_form_screen.dart`, `screens/decision_form_screen.dart`, `utils.dart` |
| Componentes reutilizáveis + identidade visual | `Panel`, `Tag`, `BulletBox`, `IndicatorTile`, `BarChart`, `AlertTile`, `ConfidenceBar`, `DecisionCard`, `CheckboxField`; tema escuro próprio (verde-água + âmbar) | `widgets.dart`, `theme.dart` |
| Acessibilidade | Descrições para leitor de tela em cartões, gráfico e clima; cabeçalhos marcados; cores sempre acompanhadas de texto; contraste alto no tema escuro; respeita o tamanho de fonte do sistema e tem ajuste próprio de **tamanho do texto** (Normal, Grande, Muito grande) em Ajustes; **sem animações de troca de tela** | todo o app, `screens/home_screen.dart` |
| Privacidade | Veja abaixo | `screens/home_screen.dart` (tela Ajustes) |

## Privacidade

- Nenhum dado pessoal: só totais por região.
- Contagens menores que 5 aparecem como `<5`.
- Os campos de texto recusam CPF, e-mail e telefone; o responsável é registrado por **cargo/setor**.
- Só o ponto central da região, arredondado (~1 km), é enviado à API de clima.
- Tudo fica no aparelho, com botão **Apagar dados salvos**.

## Fontes de dados

| Dado | Fonte |
|---|---|
| Temperatura máxima e chuva (14 dias passados + 7 de previsão) | [Open-Meteo](https://open-meteo.com), API pública e gratuita, **dado real** |
| Consumo de água e energia, resíduos e chamados | **Sintéticos**: calculados no app a partir da população e do clima real (dias quentes aumentam água e energia; chuva aumenta chamados) |
| População e localização | Aproximadas nas 3 regiões de exemplo; informadas pelo gestor nas regiões cadastradas |

## Como os alertas são calculados

- **Indicadores:** compara a média da última semana com a da anterior e supõe que a tendência continua. Se a média projetada passar de 80% da capacidade → *Observação*; 90% → *Atenção*; 100% → *Crítico*.
- **Clima:** chuva ≥ 30 mm/dia → *Atenção* (≥ 50 mm → *Crítico*); 3 ou mais dias com máxima ≥ 32 °C → calor intenso.
- **Confiança:** maior quando os dados são estáveis; menor quando o clima não está atualizado e quanto mais distante for o dia previsto.

## Limitações

- Consumo, resíduos e chamados são **simulados**; não são dados oficiais.
- A projeção é uma tendência simples e não prevê feriados, obras ou falhas na rede.
- A previsão do tempo vale para o centro da região; a chuva pode variar entre bairros.
- Sem internet, o app usa o último clima salvo; se não houver, simula o clima e **desliga os alertas climáticos**.
- Os dados ficam só no aparelho (não há sincronização entre gestores).

## Estrutura

```
lib/
├── main.dart            # inicialização e MaterialApp
├── theme.dart           # cores, tema escuro e troca de tela sem animação
├── models.dart          # Region, Indicator, DailyWeather, Alert, Decision
├── services.dart        # API Open-Meteo, armazenamento, dados sintéticos e alertas
├── app_state.dart       # estado global (Provider)
├── utils.dart           # formatação e validação
├── widgets.dart         # componentes reutilizáveis
└── screens/
    ├── home_screen.dart           # abas + tela de ajustes (acessibilidade e privacidade)
    ├── dashboard_screen.dart      # painel
    ├── region_form_screen.dart    # formulário de nova região
    ├── alerts_screen.dart         # lista e detalhe de alertas
    ├── decision_form_screen.dart  # formulário de decisão
    └── decisions_screen.dart      # histórico de decisões
test/logic_test.dart     # testes da projeção, alertas e validação
```

## Como executar

Requer Flutter 3.22 ou superior.

```bash
flutter create . --project-name radar_territorial --platforms android,ios   # só na 1ª vez
flutter pub get
flutter run
flutter test
```

Para gerar a versão final no Android, adicione a permissão de internet em `android/app/src/main/AndroidManifest.xml`, antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
