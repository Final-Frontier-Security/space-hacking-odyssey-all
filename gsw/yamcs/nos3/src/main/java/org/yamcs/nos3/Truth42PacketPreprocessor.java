package org.yamcs.nos3;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import org.yamcs.TmPacket;
import org.yamcs.YConfiguration;
import org.yamcs.tctm.AbstractPacketPreprocessor;
import org.yamcs.utils.TaiUtcConverter;
import org.yamcs.utils.TimeEncoding;

public class Truth42PacketPreprocessor extends AbstractPacketPreprocessor {
    public Truth42PacketPreprocessor(String yamcsInstance) {
        this(yamcsInstance, YConfiguration.emptyConfig());
    }
    public Truth42PacketPreprocessor(String yamcsInstance, YConfiguration config) {
        super(yamcsInstance, config);
    }

    @Override
    public TmPacket process(TmPacket packet) {
        byte[] bytes = packet.getPacket();
        if (bytes.length < 20) {
            // Not enough data to parse time; leave generationTime as-is.
            return packet;
        }

        // Known layout: BIG_ENDIAN, offset 0
        ByteBuffer bb = ByteBuffer.wrap(bytes).order(ByteOrder.BIG_ENDIAN);

        int year   = bb.getShort() & 0xFFFF; // UTC calendar fields
        bb.getShort();                       // DOY (unused)
        int month  = bb.getShort() & 0xFFFF;
        int day    = bb.getShort() & 0xFFFF;
        int hour   = bb.getShort() & 0xFFFF;
        int minute = bb.getShort() & 0xFFFF;
        double sec = bb.getDouble();         // seconds with fractional part

        int secInt = (int) Math.floor(sec);
        int msec   = (int) Math.round((sec - secInt) * 1000.0);
        if (msec == 1000) { secInt += 1; msec = 0; } 

        var dtc = new TaiUtcConverter.DateTimeComponents(year, month, day, hour, minute, secInt, msec);
        packet.setGenerationTime(TimeEncoding.fromUtc(dtc));
        return packet;
    }
}
