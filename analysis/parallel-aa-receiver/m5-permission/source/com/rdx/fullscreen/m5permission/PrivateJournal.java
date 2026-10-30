package com.rdx.fullscreen.m5permission;

import java.io.*;
import java.util.Arrays;

/** Caller supplies its own private files directory. Constructors never touch disk. */
public final class PrivateJournal {
    public static final int MAX_RUNS = 8, MAX_BYTES = 65536, MAX_LINE_BYTES = 4096;
    private final File directory;
    public PrivateJournal(File directory) {
        if (directory == null) throw new IllegalArgumentException("Missing private directory");
        this.directory = directory;
    }
    private File file(String id) {
        if (id == null || !id.matches("[A-Za-z0-9_-]{1,64}")) throw new IllegalArgumentException("Invalid run_id");
        return new File(directory, "m5-" + id + ".txt");
    }
    public String[] list() throws IOException {
        String[] names = directory.list(new FilenameFilter() {
            public boolean accept(File dir, String name) { return name.matches("m5-[A-Za-z0-9_-]{1,64}\\.txt"); }
        });
        if (names == null) throw new IOException("Cannot list private evidence");
        if (names.length > MAX_RUNS) throw new IOException("Private evidence run bound exceeded");
        Arrays.sort(names); return names;
    }
    public Session create(String id) throws IOException {
        File target = file(id);
        if (list().length >= MAX_RUNS) throw new IOException("Evidence full; no automatic deletion");
        if (!target.createNewFile()) throw new IOException("Run already exists; refusing replay/overwrite");
        Session session = new Session(target);
        try { session.record("SESSION_CREATED run=" + id); return session; }
        catch (IOException error) { session.close(); throw error; }
    }
    public byte[] read(String id) throws IOException {
        File target = file(id); long size = target.length();
        if (size < 0 || size > MAX_BYTES) throw new IOException("Evidence size bound exceeded");
        FileInputStream input = new FileInputStream(target);
        try {
            byte[] result = new byte[(int)size]; int offset = 0;
            while (offset < result.length) {
                int count = input.read(result, offset, result.length - offset);
                if (count < 0) throw new IOException("Evidence truncated during read");
                offset += count;
            }
            if (input.read() != -1) throw new IOException("Evidence grew during read");
            return result;
        } finally { input.close(); }
    }
    public static final class Session implements PermissionMachine.Evidence {
        private final FileOutputStream output;
        private int bytes;
        private Session(File target) throws IOException { output = new FileOutputStream(target, true); }
        public void record(String line) throws IOException {
            byte[] encoded = (line + "\n").getBytes("UTF-8");
            if (encoded.length > MAX_LINE_BYTES || bytes > MAX_BYTES - encoded.length)
                throw new IOException("Evidence bound exceeded; stop without retry");
            output.write(encoded); output.flush(); output.getFD().sync(); bytes += encoded.length;
        }
        public void close() throws IOException { output.close(); }
    }
}
