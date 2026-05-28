package dev.telegraphic.jbx.check;

import java.io.File;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import javax.tools.Diagnostic;
import javax.tools.DiagnosticCollector;
import javax.tools.JavaCompiler;
import javax.tools.JavaFileObject;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;

/**
 * Compiler wrapper used by {@code jbx check}.
 *
 * <p>The wrapper invokes the JDK compiler API, captures diagnostics, and prints a small JSON
 * payload consumed by the Rust CLI. It intentionally has no third-party dependencies so it can sit
 * beside Error Prone on the runtime classpath without dragging anything else in.
 */
public final class JbxCheckCompiler {
  private JbxCheckCompiler() {}

  public static void main(String[] args) throws Exception {
    List<String> options = new ArrayList<>();
    List<String> files = new ArrayList<>();
    boolean afterSeparator = false;
    for (String arg : args) {
      if (arg.equals("--")) {
        afterSeparator = true;
      } else if (afterSeparator) {
        files.add(arg);
      } else {
        options.add(arg);
      }
    }

    JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
    if (compiler == null) {
      System.err.println("No system Java compiler available. Run with a JDK, not a JRE.");
      System.exit(2);
    }

    DiagnosticCollector<JavaFileObject> diagnostics = new DiagnosticCollector<>();
    try (StandardJavaFileManager fileManager =
        compiler.getStandardFileManager(diagnostics, Locale.ROOT, StandardCharsets.UTF_8)) {
      Iterable<? extends JavaFileObject> units = fileManager.getJavaFileObjectsFromStrings(files);
      StringWriter compilerOut = new StringWriter();
      Boolean ok = compiler.getTask(compilerOut, fileManager, diagnostics, options, null, units).call();

      StringBuilder json = new StringBuilder();
      json.append("{\n  \"ok\": ").append(Boolean.TRUE.equals(ok)).append(",\n  \"diagnostics\": [\n");
      List<Diagnostic<? extends JavaFileObject>> collected = diagnostics.getDiagnostics();
      for (int i = 0; i < collected.size(); i++) {
        Diagnostic<? extends JavaFileObject> diagnostic = collected.get(i);
        json.append("    {");
        field(json, "kind", diagnostic.getKind().toString());
        json.append(",");
        field(json, "code", diagnostic.getCode());
        json.append(",");
        field(
            json,
            "file",
            diagnostic.getSource() == null
                ? null
                : new File(diagnostic.getSource().toUri()).getPath());
        json.append(",");
        json.append("\"line\": ").append(diagnostic.getLineNumber()).append(",");
        json.append("\"column\": ").append(diagnostic.getColumnNumber()).append(",");
        field(json, "message", diagnostic.getMessage(Locale.ROOT));
        json.append("}");
        if (i + 1 < collected.size()) {
          json.append(",");
        }
        json.append("\n");
      }
      json.append("  ],\n");
      field(json, "compilerOutput", compilerOut.toString());
      json.append("\n}\n");
      System.out.print(json);
      System.exit(Boolean.TRUE.equals(ok) ? 0 : 1);
    }
  }

  private static void field(StringBuilder json, String name, String value) {
    json.append("\"").append(escape(name)).append("\": ");
    if (value == null) {
      json.append("null");
    } else {
      json.append("\"").append(escape(value)).append("\"");
    }
  }

  private static String escape(String value) {
    StringBuilder escaped = new StringBuilder();
    for (int i = 0; i < value.length(); i++) {
      char c = value.charAt(i);
      switch (c) {
        case '\\':
          escaped.append("\\\\");
          break;
        case '"':
          escaped.append("\\\"");
          break;
        case '\n':
          escaped.append("\\n");
          break;
        case '\r':
          escaped.append("\\r");
          break;
        case '\t':
          escaped.append("\\t");
          break;
        default:
          if (c < 0x20) {
            escaped.append(String.format("\\u%04x", (int) c));
          } else {
            escaped.append(c);
          }
      }
    }
    return escaped.toString();
  }
}
