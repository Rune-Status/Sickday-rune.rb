module RuneRb::Network::Constants
  # A map of valid connection types
  CONNECTION_TYPES = {
    GAME_RECONNECT: 18,
    GAME_NEW: 16,
    GAME_UPDATE: 15,
    GAME_LOGIN: 14
  }.freeze
  # A map of sidebar interface menu_ids -> form ids
  SIDEBAR_INTERFACES = { 0 => 2423, # ATTACK
                         1 => 3917, # SKILL
                         2 => 638,  # QUEST
                         3 => 3213, # INVENT
                         4 => 1644, # EQUIPMENT
                         5 => 5608, # PRAYER
                         6 => 1151, # NORMAL SPELLS = 1151, ANCIENT = 12855
                         8 => 5065, # FRIENDS
                         9 => 5715, # IGNORE
                         10 => 2449, # LOGOUT
                         11 => 904, # WRENCH
                         12 => 147, # EMOTE
                         13 => 962 }.freeze # MUSIC
  # Acceptable byte orders in which multi-byte values can be read.
  BYTE_ORDERS = %i[BIG MIDDLE INVERSE_MIDDLE LITTLE].freeze
  # Acceptable read types for data.
  READ_TYPES = %i[OFFSET NEGATIVE_OFFSET POST_NEGATIVE_OFFSET PRE_NEGATIVE_OFFSET
                  INVERTED NEGATIVE].freeze
  BYTE_TYPES = %i[A a C c S s STD std].freeze
  # Bit masks for bit packing
  BIT_MASK_OUT = (0...32).collect { |i| (1 << i) - 1 }
  # A map of frame operation codes -> frame size
  FRAME_SIZES = { 0 => 0, 1 => 0, 2 => 0, 3 => 1, 4 => -1, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0,
                  11 => 0, 12 => 0, 13 => 0, 14 => 8, 15 => 0, 16 => 6, 17 => 2, 18 => 2, 19 => 0, 20 => 0,
                  21 => 2, 22 => 0, 23 => 6, 24 => 0, 25 => 12, 26 => 0, 27 => 0, 28 => 0, 29 => 0, 30 => 0,
                  31 => 0, 32 => 0, 33 => 0, 34 => 0, 35 => 8, 36 => 4, 37 => 0, 38 => 0, 39 => 2, 40 => 2,
                  41 => 6, 42 => 0, 43 => 6, 44 => 0, 45 => -1, 46 => 0, 47 => 0, 48 => 0, 49 => 0, 50 => 0,
                  51 => 0, 52 => 0, 53 => 12, 54 => 0, 55 => 0, 56 => 0, 57 => 8, 58 => 0, 59 => 0, 60 => 0,
                  61 => 8, 62 => 0, 63 => 0, 64 => 0, 65 => 0, 66 => 0, 67 => 0, 68 => 0, 69 => 0, 70 => 6,
                  71 => 0, 72 => 2, 73 => 2, 74 => 8, 75 => 6, 76 => 0, 77 => -1, 78 => 0, 79 => 6, 80 => 0,
                  81 => 0, 82 => 0, 83 => 0, 84 => 0, 85 => 1, 86 => 4, 87 => 6, 88 => 0, 89 => 0, 90 => 0,
                  91 => 0, 92 => 0, 93 => 0, 94 => 0, 95 => 3, 96 => 0, 97 => 0, 98 => -1, 99 => 0, 100 => 0,
                  101 => 13, 102 => 0, 103 => -1, 104 => 0, 105 => 0, 106 => 0, 107 => 0, 108 => 0, 109 => 0, 110 => 0,
                  111 => 0, 112 => 0, 113 => 0, 114 => 0, 115 => 0, 116 => 0, 117 => 6, 118 => 0, 119 => 0, 120 => 1,
                  121 => 0, 122 => 6, 123 => 0, 124 => 0, 125 => 0, 126 => -1, 127 => 0, 128 => 2, 129 => 6, 130 => 0,
                  131 => 4, 132 => 6, 133 => 8, 134 => 0, 135 => 6, 136 => 0, 137 => 0, 138 => 0, 139 => 2, 140 => 0,
                  141 => 0, 142 => 0, 143 => 0, 144 => 0, 145 => 6, 146 => 0, 147 => 0, 148 => 0, 149 => 0, 150 => 0,
                  151 => 0, 152 => 1, 153 => 2, 154 => 0, 155 => 2, 156 => 6, 157 => 0, 158 => 0, 159 => 0, 160 => 0,
                  161 => 0, 162 => 0, 163 => 0, 164 => -1, 165 => -1, 166 => 0, 167 => 0, 168 => 0, 169 => 0, 170 => 0,
                  171 => 0, 172 => 0, 173 => 0, 174 => 0, 175 => 0, 176 => 0, 177 => 0, 178 => 0, 179 => 0, 180 => 0,
                  181 => 8, 182 => 0, 183 => 3, 184 => 0, 185 => 2, 186 => 0, 187 => 0, 188 => 8, 189 => 1, 190 => 0,
                  191 => 0, 192 => 12, 193 => 0, 194 => 0, 195 => 0, 196 => 0, 197 => 0, 198 => 0, 199 => 0, 200 => 2,
                  201 => 0, 202 => 0, 203 => 0, 204 => 0, 205 => 0, 206 => 0, 207 => 0, 208 => 4, 209 => 0, 210 => 4,
                  211 => 0, 212 => 0, 213 => 0, 214 => 7, 215 => 8, 216 => 0, 217 => 0, 218 => 10, 219 => 0, 220 => 0,
                  221 => 0, 222 => 0, 223 => 0, 224 => 0, 225 => 0, 226 => -1, 227 => 0, 228 => 6, 229 => 0, 230 => 1,
                  231 => 0, 232 => 0, 233 => 0, 234 => 6, 235 => 0, 236 => 6, 237 => 8, 238 => 1, 239 => 0, 240 => 0,
                  241 => 4, 242 => 0, 243 => 0, 244 => 0, 245 => 0, 246 => -1, 247 => 0, 248 => -1, 249 => 4, 250 => 0,
                  251 => 0, 252 => 6, 253 => 6, 254 => 0, 255 => 0, 256 => 0 }.freeze
end