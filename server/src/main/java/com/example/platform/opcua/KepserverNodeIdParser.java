package com.example.platform.opcua;

import org.eclipse.milo.opcua.stack.core.types.builtin.NodeId;

import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class KepserverNodeIdParser {

    private static final Pattern KEP_STRING_PATTERN = Pattern.compile("^NS(\\d+)\\|String\\|(.+)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern OPCUA_STRING_PATTERN = Pattern.compile("^ns=(\\d+);s=(.+)$", Pattern.CASE_INSENSITIVE);

    private KepserverNodeIdParser() {
    }

    public static NodeId parse(String rawSourcePath, int defaultNamespaceIndex) {
        String sourcePath = trim(rawSourcePath);
        Matcher kepMatcher = KEP_STRING_PATTERN.matcher(sourcePath);
        if (kepMatcher.matches()) {
            return new NodeId(Integer.parseInt(kepMatcher.group(1)), kepMatcher.group(2));
        }

        Matcher opcuaMatcher = OPCUA_STRING_PATTERN.matcher(sourcePath);
        if (opcuaMatcher.matches()) {
            return new NodeId(Integer.parseInt(opcuaMatcher.group(1)), opcuaMatcher.group(2));
        }

        return new NodeId(defaultNamespaceIndex, sourcePath);
    }

    public static Optional<String> identifier(String rawSourcePath) {
        String sourcePath = trim(rawSourcePath);
        if (sourcePath.isBlank()) {
            return Optional.empty();
        }

        Matcher kepMatcher = KEP_STRING_PATTERN.matcher(sourcePath);
        if (kepMatcher.matches()) {
            return Optional.of(kepMatcher.group(2));
        }

        Matcher opcuaMatcher = OPCUA_STRING_PATTERN.matcher(sourcePath);
        if (opcuaMatcher.matches()) {
            return Optional.of(opcuaMatcher.group(2));
        }

        return Optional.of(sourcePath);
    }

    public static String kepString(int namespaceIndex, String identifier) {
        return "NS" + namespaceIndex + "|String|" + identifier;
    }

    public static String opcuaString(int namespaceIndex, String identifier) {
        return "ns=" + namespaceIndex + ";s=" + identifier;
    }

    private static String trim(String raw) {
        return raw == null ? "" : raw.trim();
    }
}
