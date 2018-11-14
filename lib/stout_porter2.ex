#
#    StoutPorter2 - efficient implementation of the English Porter2 stemming algorithm.
#    Copyright (C) 2018 Patrick Tschorn
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
defmodule StoutPorter2 do
  @moduledoc """
  Efficient implementation of the [English Porter2 stemming algorithm](http://snowballstem.org/algorithms/english/stemmer.html).
  """

  #@compile :native
  #@compile [:native, {:hipe, [:o3]}]

  @doc """
  Reduces a word to its stem.

  ## Parameters

    - word (string): word to be stemmed

  ## Example

      iex> StoutPorter2.stem("hopped")
      "hop"
  """
  @spec stem(String.t()) :: String.t()
  def stem(word) when is_binary(word),
    # each step is threaded into the next, so we just call the very first step here...
    do: prelude_mark_regions(word)

  defmacrop is_vowel(cp) do
    quote do
      unquote(cp) == ?e or unquote(cp) == ?a or unquote(cp) == ?o or unquote(cp) == ?i or
        unquote(cp) == ?u or unquote(cp) == ?y
    end
  end

  defp contains_vowel([cp | _rest]) when is_vowel(cp), do: true
  defp contains_vowel([_ | rest]), do: contains_vowel(rest)
  defp contains_vowel([]), do: false

  defmacrop is_double(cp) do
    quote do
      unquote(cp) == ?b or unquote(cp) == ?d or unquote(cp) == ?f or unquote(cp) == ?g or
        unquote(cp) == ?m or unquote(cp) == ?n or unquote(cp) == ?p or unquote(cp) == ?r or
        unquote(cp) == ?t
    end
  end

  defmacrop is_non_vowel(cp) do
    quote do
      not is_vowel(unquote(cp))
    end
  end

  defmacrop is_non_vowel2(cp) do
    quote do
      not is_vowel(unquote(cp)) and unquote(cp) != ?w and unquote(cp) != ?x and unquote(cp) != ?Y
    end
  end

  defmacrop is_valid_li(cp) do
    quote do
      unquote(cp) == ?c or unquote(cp) == ?d or unquote(cp) == ?e or unquote(cp) == ?g or
        unquote(cp) == ?h or unquote(cp) == ?k or unquote(cp) == ?m or unquote(cp) == ?n or
        unquote(cp) == ?r or unquote(cp) == ?t
    end
  end

  defp prelude_mark_regions(s), do: pre_mr(String.downcase(s), [], 0, false, false, [])

  defp pre_mr(<<_c1::utf8, _c2::utf8>> = w, [], 0, false, _, _), do: w
  defp pre_mr(<<_c1::utf8>> = w, [], 0, false, _, _), do: w

  # string, char_acc, len, leading_apostrophe_flag, pre_is_vowel, [r1,r2]
  defp pre_mr(<<cp::utf8, rest::binary>>, [], 0, false, _, []) when cp == ?',
    do: pre_mr(rest, [], 0, true, false, [])

  defp pre_mr("gener" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?r, ?e, ?n, ?e, ?g], 5, la_flag, false, [5])

  defp pre_mr("commun" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?n, ?u, ?m, ?m, ?o, ?c], 6, la_flag, false, [6])

  defp pre_mr("arsen" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?n, ?e, ?s, ?r, ?a], 5, la_flag, false, [5])

  # spotting exception1 cases as part of prelude & mark_regions; directly exiting with special case results
  defp pre_mr("andes" = w, _, 0, _, _, _), do: w
  defp pre_mr("atlas" = w, _, 0, _, _, _), do: w
  defp pre_mr("bias" = w, _, 0, _, _, _), do: w
  defp pre_mr("cosmos" = w, _, 0, _, _, _), do: w
  defp pre_mr("howe" = w, _, 0, _, _, _), do: w
  defp pre_mr("news" = w, _, 0, _, _, _), do: w
  defp pre_mr("sky" = w, _, 0, _, _, _), do: w
  defp pre_mr("skis", _, 0, _, _, _), do: "ski"
  defp pre_mr("skies", _, 0, _, _, _), do: "sky"
  defp pre_mr("dying", _, 0, _, _, _), do: "die"
  defp pre_mr("lying", _, 0, _, _, _), do: "lie"
  defp pre_mr("tying", _, 0, _, _, _), do: "tie"
  defp pre_mr("idly", _, 0, _, _, _), do: "idl"
  defp pre_mr("gently", _, 0, _, _, _), do: "gentl"
  defp pre_mr("ugly", _, 0, _, _, _), do: "ugli"
  defp pre_mr("early", _, 0, _, _, _), do: "earli"
  defp pre_mr("only", _, 0, _, _, _), do: "onli"
  defp pre_mr("singly", _, 0, _, _, _), do: "singl"

  defp pre_mr(<<cp::utf8, rest::binary>>, [], 0, la_flag, _, []) when cp == ?y,
    do: pre_mr(rest, [?Y], 1, la_flag, false, [])

  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, true, r1r2) when cp == ?y do
    if length(r1r2) < 2 do
      pre_mr(rest, [?Y | acc], len + 1, la_flag, false, [len + 1 | r1r2])
    else
      pre_mr(rest, [?Y | acc], len + 1, la_flag, false, r1r2)
    end
  end

  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, true, r1r2) when length(r1r2) < 2 do
    case is_vowel(cp) do
      false -> pre_mr(rest, [cp | acc], len + 1, la_flag, false, [len + 1 | r1r2])
      true -> pre_mr(rest, [cp | acc], len + 1, la_flag, true, r1r2)
    end
  end

  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, _, r1r2) do
    pre_mr(rest, [cp | acc], len + 1, la_flag, is_vowel(cp), r1r2)
  end

  # prelude + mark regions complete, carry on with step0
  defp pre_mr(<<>>, acc, len, _la_flag, _, [r2, r1]), do: step0(acc, len, r1, r2)

  defp pre_mr(<<>>, acc, len, _la_flag, _, [r1]), do: step0(acc, len, r1, len)

  defp pre_mr(<<>>, acc, len, _la_flag, _, []), do: step0(acc, len, len, len)

  defp step0([?', ?s, ?' | rest], len, r1, r2), do: step1a(rest, len - 3, r1, r2)

  defp step0([?s, ?' | rest], len, r1, r2), do: step1a(rest, len - 2, r1, r2)

  defp step0([?' | rest], len, r1, r2), do: step1a(rest, len - 1, r1, r2)

  defp step0(rest, len, r1, r2), do: step1a(rest, len, r1, r2)

  defp step1a([?s, ?e, ?s, ?s | rest], len, r1, r2),
    do: exception2([?s, ?s | rest], len - 2, r1, r2)

  defp step1a([sd, ?e, ?i, cp1, cp2 | rest], len, r1, r2) when sd == ?s or sd == ?d,
    do: exception2([?i, cp1, cp2 | rest], len - 2, r1, r2)

  defp step1a([sd, ?e, ?i | rest], len, r1, r2) when sd == ?s or sd == ?d,
    do: exception2([?e, ?i | rest], len - 1, r1, r2)

  defp step1a([?s, su | rest], len, r1, r2) when su == ?s or su == ?u,
    do: exception2([?s, su | rest], len, r1, r2)

  defp step1a([?s, cp | rest] = w, len, r1, r2) do
    case contains_vowel(rest) do
      true -> exception2([cp | rest], len - 1, r1, r2)
      false -> exception2(w, len, r1, r2)
    end
  end

  # catchall, nothing else in step1a is applicable...
  defp step1a(rest, len, r1, r2), do: exception2(rest, len, r1, r2)

  defp exception2([?g, ?n, ?i, ?n, ?n, ?i] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?g, ?n, ?i, ?t, ?u, ?o] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?g, ?n, ?i, ?n, ?n, ?a, ?c] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?g, ?n, ?i, ?r, ?r, ?e, ?h] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?g, ?n, ?i, ?r, ?r, ?a, ?e] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?d, ?e, ?e, ?c, ?o, ?r, ?p] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?d, ?e, ?e, ?c, ?x, ?e] = w, _len, _r1, _r2), do: postlude(w)
  defp exception2([?d, ?e, ?e, ?c, ?c, ?u, ?s] = w, _len, _r1, _r2), do: postlude(w)

  # not exceptional after all
  defp exception2(w, len, r1, r2), do: step1b(w, len, r1, r2)

  defp step1b([?y, ?l, ?d, ?e, ?e | rest] = w, len, r1, r2) do
    if len - 5 >= r1 do
      step1c([?e, ?e | rest], len - 3, r1, r2)
    else
      step1c(w, len, r1, r2)
    end
  end

  defp step1b([?d, ?e, ?e | rest] = w, len, r1, r2) do
    if len - 3 >= r1 do
      step1c([?e, ?e | rest], len - 1, r1, r2)
    else
      step1c(w, len, r1, r2)
    end
  end

  defp step1b([?y, ?l, ?g, ?n, ?i | rest] = w, len, r1, r2) do
    case contains_vowel(rest) do
      true -> s1b(rest, len - 5, r1, r2)
      false -> step1c(w, len, r1, r2)
    end
  end

  defp step1b([?g, ?n, ?i | rest] = w, len, r1, r2) do
    case contains_vowel(rest) do
      true -> s1b(rest, len - 3, r1, r2)
      false -> step1c(w, len, r1, r2)
    end
  end

  defp step1b([?y, ?l, ?d, ?e | rest] = w, len, r1, r2) do
    case contains_vowel(rest) do
      true -> s1b(rest, len - 4, r1, r2)
      false -> step1c(w, len, r1, r2)
    end
  end

  defp step1b([?d, ?e | rest] = w, len, r1, r2) do
    case contains_vowel(rest) do
      true -> s1b(rest, len - 2, r1, r2)
      false -> step1c(w, len, r1, r2)
    end
  end

  defp step1b(rest, len, r1, r2), do: step1c(rest, len, r1, r2)

  defp s1b([tlz, abi | rest], len, r1, r2)
       when (tlz == ?t and abi == ?a) or (tlz == ?l and abi == ?b) or (tlz == ?z and abi == ?i),
       do: step1c([?e, tlz, abi | rest], len + 1, r1, r2)

  defp s1b([cp, cp | rest], len, r1, r2) when is_double(cp),
    do: step1c([cp | rest], len - 1, r1, r2)

  defp s1b(w, len, r1, r2) do
    case ends_with_short_syllable(w) and r1 >= len do
      true -> step1c([?e | w], len + 1, r1, r2)
      false -> step1c(w, len, r1, r2)
    end
  end

  defp ends_with_short_syllable([c2, v, c1 | _])
       when is_vowel(v) and is_non_vowel(c1) and is_non_vowel2(c2),
       do: true

  defp ends_with_short_syllable([c2, v]) when is_vowel(v) and is_non_vowel(c2), do: true
  defp ends_with_short_syllable(_), do: false

  defp step1c([yY, c1, c2 | rest], len, r1, r2) when (yY == ?y or yY == ?Y) and is_non_vowel(c1),
    do: step2([?i, c1, c2 | rest], len, r1, r2)

  defp step1c(rest, len, r1, r2), do: step2(rest, len, r1, r2)

  defp step2([?n, ?o, ?i, ?t, ?a, ?z, ?i | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?e, ?z, ?i | rest], len - 4, r1, r2)

  defp step2([?l, ?a, ?n, ?o, ?i, ?t, ?a | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?e, ?t, ?a | rest], len - 4, r1, r2)

  defp step2([?s, ?s, ?e, ?n, ?l, ?u, ?f | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?l, ?u, ?f | rest], len - 4, r1, r2)

  defp step2([?s, ?s, ?e, ?n, ?s, ?u, ?o | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?s, ?u, ?o | rest], len - 4, r1, r2)

  defp step2([?s, ?s, ?e, ?n, ?e, ?v, ?i | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?e, ?v, ?i | rest], len - 4, r1, r2)

  defp step2([?l, ?a, ?n, ?o, ?i, ?t | rest], len, r1, r2) when len - 6 >= r1,
    do: step3([?n, ?o, ?i, ?t | rest], len - 2, r1, r2)

  defp step2([?i, ?t, ?i, ?l, ?i, ?b | rest], len, r1, r2) when len - 6 >= r1,
    do: step3([?e, ?l, ?b | rest], len - 3, r1, r2)

  defp step2([?i, ?l, ?s, ?s, ?e, ?l | rest], len, r1, r2) when len - 6 >= r1,
    do: step3([?s, ?s, ?e, ?l | rest], len - 2, r1, r2)

  defp step2([?i, ?t, ?i, ?v, ?i | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?e, ?v, ?i | rest], len - 2, r1, r2)

  defp step2([?i, ?l, ?s, ?u, ?o | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?s, ?u, ?o | rest], len - 2, r1, r2)

  defp step2([?n, ?o, ?i, ?t, ?a | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?e, ?t, ?a | rest], len - 2, r1, r2)

  # TODO determine if other cases need similar treatment...
  defp step2([?i, ?l, ?t, ?n, ?e | rest] = w, len, r1, r2) do
    if len - 5 >= r1 do
      step3([?t, ?n, ?e | rest], len - 2, r1, r2)
    else
      step3(w, len, r1, r2)
    end
  end

  defp step2([?m, ?s, ?i, ?l, ?a | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?l, ?a | rest], len - 3, r1, r2)

  defp step2([?i, ?t, ?i, ?l, ?a | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?l, ?a | rest], len - 3, r1, r2)

  defp step2([?i, ?l, ?l, ?u, ?f | rest], len, r1, r2) when len - 5 >= r1,
    do: step3([?l, ?u, ?f | rest], len - 2, r1, r2)

  defp step2([?i, ?c, ?n, ?e | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?e, ?c, ?n, ?e | rest], len, r1, r2)

  defp step2([?i, ?c, ?n, ?a | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?e, ?c, ?n, ?a | rest], len, r1, r2)

  defp step2([?i, ?l, ?b, ?a | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?e, ?l, ?b, ?a | rest], len, r1, r2)

  defp step2([?r, ?e, ?z, ?i | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?e, ?z, ?i | rest], len - 1, r1, r2)

  defp step2([?r, ?o, ?t, ?a | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?e, ?t, ?a | rest], len - 1, r1, r2)

  defp step2([?i, ?l, ?l, ?a | rest], len, r1, r2) when len - 4 >= r1,
    do: step3([?l, ?a | rest], len - 2, r1, r2)

  defp step2([?i, ?g, ?o, ?l | rest], len, r1, r2) when len - 3 >= r1,
    do: step3([?g, ?o, ?l | rest], len - 1, r1, r2)

  defp step2([?i, ?l, ?b | rest], len, r1, r2) when len - 3 >= r1,
    do: step3([?e, ?l, ?b | rest], len, r1, r2)

  defp step2([?i, ?l, cp | rest], len, r1, r2) when len - 2 >= r1 and is_valid_li(cp),
    do: step3([cp | rest], len - 2, r1, r2)

  defp step2(rest, len, r1, r2),
    do: step3(rest, len, r1, r2)

  defp step3([?l, ?a, ?n, ?o, ?i, ?t, ?a | rest], len, r1, r2) when len - 7 >= r1,
    do: step4([?e, ?t, ?a | rest], len - 4, r1, r2)

  defp step3([?l, ?a, ?n, ?o, ?i, ?t | rest], len, r1, r2) when len - 6 >= r1,
    do: step4([?n, ?o, ?i, ?t | rest], len - 2, r1, r2)

  defp step3([?e, ?z, ?i, ?l, ?a | rest], len, r1, r2) when len - 5 >= r1,
    do: step4([?l, ?a | rest], len - 3, r1, r2)

  defp step3([?e, ?v, ?i, ?t, ?a | rest], len, r1, r2) when len - 5 >= r2,
    do: step4(rest, len - 5, r1, r2)

  defp step3([?e, ?t, ?a, ?c, ?i | rest], len, r1, r2) when len - 5 >= r1,
    do: step4([?c, ?i | rest], len - 3, r1, r2)

  defp step3([?i, ?t, ?i, ?c, ?i | rest], len, r1, r2) when len - 5 >= r1,
    do: step4([?c, ?i | rest], len - 3, r1, r2)

  defp step3([?l, ?a, ?c, ?i | rest], len, r1, r2) when len - 4 >= r1,
    do: step4([?c, ?i | rest], len - 2, r1, r2)

  defp step3([?s, ?s, ?e, ?n | rest], len, r1, r2) when len - 4 >= r1,
    do: step4(rest, len - 4, r1, r2)

  defp step3([?l, ?u, ?f | rest], len, r1, r2) when len - 3 >= r1,
    do: step4(rest, len - 3, r1, r2)

  defp step3(rest, len, r1, r2), do: step4(rest, len, r1, r2)

  defp step4([?t, ?n, ?e, ?m, ?e | rest] = w, len, r1, r2) do
    if len - 5 >= r2 do
      step5(rest, len - 5, r1, r2)
    else
      step5(w, len, r1, r2)
    end
  end

  defp step4([?t, ?n, ?e, ?m | rest] = w, len, r1, r2) do
    if len - 4 >= r2 do
      step5(rest, len - 4, r1, r2)
    else
      step5(w, len, r1, r2)
    end
  end

  defp step4([?t, ?n, ?e | rest] = w, len, r1, r2) do
    if len - 3 >= r2 do
      step5(rest, len - 3, r1, r2)
    else
      step5(w, len, r1, r2)
    end
  end

  defp step4([?e, ?c, ?n, ?a | rest], len, r1, r2) when len - 4 >= r2,
    do: step5(rest, len - 4, r1, r2)

  defp step4([?e, ?c, ?n, ?e | rest], len, r1, r2) when len - 4 >= r2,
    do: step5(rest, len - 4, r1, r2)

  defp step4([?e, ?l, ?b, ai | rest], len, r1, r2) when len - 4 >= r2 and (ai == ?a or ai == ?i),
    do: step5(rest, len - 4, r1, r2)

  defp step4([?n, ?o, ?i, st | rest], len, r1, r2) when len - 3 >= r2 and (st == ?s or st == ?t),
    do: step5([st | rest], len - 3, r1, r2)

  defp step4([?t, ?n, ?a | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?m, ?s, ?i | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?e, ?t, ?a | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?i, ?t, ?i | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?s, ?u, ?o | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?e, ?v, ?i | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?e, ?z, ?i | rest], len, r1, r2) when len - 3 >= r2,
    do: step5(rest, len - 3, r1, r2)

  defp step4([?l, ?a | rest], len, r1, r2) when len - 2 >= r2, do: step5(rest, len - 2, r1, r2)
  defp step4([?r, ?e | rest], len, r1, r2) when len - 2 >= r2, do: step5(rest, len - 2, r1, r2)
  defp step4([?c, ?i | rest], len, r1, r2) when len - 2 >= r2, do: step5(rest, len - 2, r1, r2)

  defp step4(rest, len, r1, r2), do: step5(rest, len, r1, r2)

  defp step5([?e | rest], len, _r1, r2) when len - 1 >= r2, do: postlude(rest)

  defp step5([?e | rest] = w, len, r1, _r2) when len - 1 >= r1 do
    case ends_with_short_syllable(rest) do
      true -> postlude(w)
      false -> postlude(rest)
    end
  end

  defp step5([?l, ?l | rest], len, _r1, r2) when len - 1 >= r2, do: postlude([?l | rest])
  defp step5(rest, _len, _r1, _r2), do: postlude(rest)

  defp postlude(w) do
    :lists.reverse(w)
    |> IO.iodata_to_binary()
    |> String.downcase()
  end
end
