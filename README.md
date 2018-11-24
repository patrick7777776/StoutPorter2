# StoutPorter2
Efficient Elixir implementation of the [English Porter2 stemming algorithm](http://snowballstem.org/algorithms/english/stemmer.html).

## Mix

      {:stout_porter2, "~> 0.1.1"}

## Example

      iex> StoutPorter2.stem("hopped")
      "hop"



## Stemming

Stemming reduces inflected/derived word forms to a common base form, the stem, in order to improve the performance of information retrieval systems. For example, when both indices and queries operate on stems, _car_, _cars_, _car's_, _cars'_ are all conflated to _car_.
In contrast to lemmatization, stemming works by heuristically removing/replacing string suffixes without the use of sophisticated morphological analysis or comprehensive dictionaries.

The most widely used stemming approach for English is the Porter stemming algorithm, cleverly devised by Dr. Martin Porter in 1979, and subsequently revised. Its most up-to-date definition is known as Porter2 and has been stable for well over a decade.  A full definition of the Porter2 stemmer with explanations and an implementation in Snowball (a small string processing language) is available on [Dr. Porter's web-site](http://snowball.tartarus.org/algorithms/english/stemmer.html) as well as on [the official Snowball site](http://snowballstem.org/algorithms/english/stemmer.html).


## Overview of the Porter2 algorithm


The main function of Porter2 in the [Snowball reference implementation](http://snowballstem.org/algorithms/english/stemmer.html) is as follows:

```
 1:  define stem as (
 2:    exception1 or
 3:    not hop 3 or (
 4:      do prelude
 5:      do mark_regions
 6:      backwards (
 7:        do Step_1a
 8:        exception2 or (
 9:          do Step_1b
10:          do Step_1c
11:          do Step_2
12:          do Step_3
13:          do Step_4
14:          do Step_5
15:        )
16:      )
17:      do postlude
18:    )
19:  )
```


The stem function requires its input word to be in lowercase and transforms it into a stem
through a sequence of steps.

There are three conditions under which all or part of the sequence can be skipped:

1. exception1 (line 2): the word matches one of 18 exceptional word forms (such as _andes_, _cosmos_, _sky_, _skies_) that get mapped to their stem directly via a small dictionary. 

2. not hop 3 (line 3): words that are shorter than three characters are returned as is.

3. exception2 (line 8): the word has been transformed into one of 8 exceptional forms (such as _earring_, _succeed_) for which no further transformation is desirable.

The standard path of excecution begins with prelude (line 4).

### prelude

If the word starts with a **'**, prelude removes it.  The letter **y** can function as a vowel or as a consonant, and prelude marks **y**s that function as consonants by upcasing them.  Specifically, prelude upcases the first occurrence of the letter **y** and each **y** that follows a vowel.  The ultimate processing step, postlude, will revoke any such upcasings before returning the final result. (The upcasing convention works as the input word is required to be lowercase.) 

### mark_regions

Mark_regions scans the input word for occurrences of the pattern [vowel, non-vowel]. Region 1 (R1) begins after the first occurrence of the pattern, and Region 2 (R2) begins after the second occurrence of the pattern. R1 and R2 may be the empty string. Some of the steps in Porter2 only apply if a certain suffix is found within R1 or R2.
There are three special cases when determining R1: when the word begins with _arsen_, _commun_ or _gener_, R1 is set to the remainder of the word.

The actual transformation steps are concerned with removing or altering suffixes of the input string.  Snowball caters to this situation via its backward processing mode (line 6), which ensures that the generated code processes characters right-to-left to avoid unnecessary string traversal operations.  (This insight is especially relevant for an implementation in Elixir/Erlang, where traversals are implemented through recursion and where manipulating the front of a list/binary is much faster than manipulating the tail.)

In general, each step commits to the longest matching suffix (from a specified set) and then, if all required conditions are met, carries out a transformation. If the conditions are not met or no match can be made, the input string is returned unaltered. The stem function moves the input string through the various steps.

### Step_1a

Step_1a first removes **'s'**, **'s** or **'** (aka Step0)

| Suffix  | Action           | Example   
|---------|------------------|-----------
| **'s'**     | remove           |  
| **'s**      | remove           | cat's → cat
| **'**       | remove           | gaps' → gaps

and then:

| Suffix     | Action   | Example   
|------------|----------|-----------
| **sses**           | replace by **ss**                                                                | masses → mass 
| **ied** / **ies**  | replace by **i** if preceded by more than one letter, otherwise replace by **ie**   | ties → tie ; cries → cri 
| **us** / **ss**    | keep as is                                                                   | miss → miss 
| **s**              | delete if preceding word part contains a vowel not immediately before the **s** | gaps → gap 


### Step_1b

| Suffix                  | Action    | Example   
|-------------------------|-----------|-----------
| **eedly** / **eed**     | replace by **ee** if in R1                                  | guaranteed → guarantee   
| **edly** / **ed** / **ingly** / **ing** | delete if the preceding word part contains a vowel and then <br> add **e** if transformed word is short or ends in **at** / **bl** / **iz**, or <br> remove last letter if transformed word ends in double letter | luxuriated → luxuriate ; hoped → hope ; hopped → hop  

A word is short if it ends in a short syllable and R1 is the empty string.
A short syllable is either the pattern [vowel, non-vowel] at the beginning of the word or the pattern [non-vowel, vowel, non-vowel other than **w** / **x** / **Y**].
Double letters are **bb** / **dd** / **ff** / **gg** / **mm** / **nn** / **pp** / **rr** / **tt**.

### Step_1c

| Suffix     | Action   | Example   
|------------|----------|-----------
| **y** / **Y**     | replace by **i** if preceded by a non-vowel which is not the first letter of the word | fly → fli 


### Step_2

| Suffix     | Action     | Example   
|------------|------------|-----------
| **ational**    | replace by **ate** if present in R1 | confrontational → confrontate |
| **fulness**    | replace by **ful** if present in R1 | hopefulness → hopeful |
| **iveness**    | replace by **ive** if present in R1 | forgiveness → forgive |
| **ization**    | replace by **ize** if present in R1 | civilization → civilize |
| **ousness**    | replace by **ous** if present in R1 | consciousness → conscious |
| **biliti**     | replace by **ble**  if present in R1 | accountabiliti → accountable |
| **lessli**     | replace by **less** if present in R1 | endlessli → endless |
| **tional**     | replace by **tion** if present in R1 | functional → function |
| **alism**      | replace by **al** if present in R1 | cannibalism → cannibal |
| **aliti**      | replace by **al** if present in R1 | convivialiti → convivial |
| **ation**      | replace by **ate** if present in R1 | temptation → temptate |
| **entli**      | replace by **ent** if present in R1 | confidentli → confident |
| **fulli**      | replace by **ful** if present in R1 | resentfulli → resentful |
| **iviti**      | replace by **ive** if present in R1 | captiviti → captive |
| **ousli**      | replace by **ous** if present in R1 | suspiciousli → suspicious |
| **abli**       | replace by **able** if present in R1 | considerabli → considerable |
| **alli**       | replace by **al** if present in R1 | dramaticalli → dramatical |
| **ator**       | replace by **ate** if present in R1 | naviagtor → navigate |
| **anci**       | replace by **ance** if present in R1 | eleganci → elegance |
| **enci**       | replace by **ence** if present in R1 | ascendenci → ascendence |
| **izer**       | replace by **ize** if present in R1 | stabilizer → stabilize |
| **bli**        | replace by **ble** if present in R1 | possibli → possible |
| **ogi**        | replace by **og** if present in R1 and preceded by **l** | analogi → analog |
| **li**         | delete if present in R1 and preceded by li-ending | coarseli → coarse |


li-endings are **c** / **d** / **e** / **g** / **h** / **k** / **m** / **n** / **r** / **t**.

### Step_3

| Suffix     | Action    | Example   
|------------|-----------|-----------
| **ational**    | replace by **ate** if present in R1 | conversational → conversate |
| **tional**     | replace by **tion** if present in R1 |additional → addition |
| **alize**      | replace by **al** if present in R1 | tantalize → tantal |
| **ative**      | delete if present in R2 | initiative → initi |
| **icate**      | replace by **ic** if present in R1 | vindicate → vindic |
| **iciti**      | replace by **ic** if present in R1 | authenticiti → authentic |
| **ical**       | replace by **ic** if present in R1 | dramatical → dramatic |
| **ness**       | delete if present in R1 | aptness → apt 
| **ful**        | delete if present in R1 | mindful → mind |


### Step_4

| Suffix     | Action   | Example  
|------------|----------|----------
| **ement**      | delete if present in R2 | disagreement → disagre |
| **able**       | delete if present in R2 | considerable → consider |
| **ance**       | delete if present in R2 | petulance → petul | 
| **ence**       | delete if present in R2 | ascendence → ascend |
| **ible**       | delete if present in R2 | infallible → infall |
| **ment**       | delete if present in R2 | impediment → impedi |
| **ant**        | delete if present in R2 | ruminant → rumin |
| **ate**        | delete if present in R2 | confrontate → confront |
| **ent**        | delete if present in R2 | precedent → preced |
| **ism**        | delete if present in R2 | mechanism → mechan |
| **ion**        | delete if present in R2 and preceded by **s** / **t** | persecution → persecut |
| **iti**        | delete if present in R2 | peculiariti → peculiar |
| **ive**        | delete if present in R2 | inexpressive → inexpress |
| **ize**        | delete if present in R2 | stabilize → stabil |
| **ous**        | delete if present in R2 | suspicious → suspici |
| **al**         | delete if present in R2 | perusal → perus |
| **er**         | delete if present in R2 | gamekeeper → gamekeep |
| **ic**         | delete if present in R2 | dramatic → dramat |


### Step_5

| Suffix     | Action   | Example           
|------------|----------|-------------------
| **e**          | delete if in R2 or in R1 and not preceded by a short syllable | realize → realiz  
| **l**          | delete if in R2 and preceded by **l**                         | infall → infal   


### postlude

Lowercases the result of the transformation.




## Implementation considerations

On the road to an efficient Porter2 implementation in Elixir
there are two areas to consider:

1. the Porter2 algorithm itself, and
2. writing BEAM-friendly code (BEAM is the Elixir/Erlang VM).

In terms of the algorithm, it is worth noting that:

* The steps prelude and mark_regions can be performed in a single loop, and some handling of exceptional cases can be folded in as well.

* There is no need to have a main function that ferries intermediate results from step to step; instead the step functions can be 'threaded' together directly.  

In terms of writing BEAM-friendly code, it is worth noting that:

* Matching / manipulating the front of binaries / lists is fast (as opposed to manipulating the tail).  Almost all Porter2 processing is suffix-oriented. Thus, the step functions should operate on reversed input, making good use of pattern matching and guards.

* BEAM has a fast built-in regular expression engine that will generally outperform hand-crafted Elixir string processing code, unless the strings are short, which tends to be the case here.

* Recursive list traversal is faster than recursive binary traversal. Elixir strings are UTF-8-encoded binaries. A conversion to a reversed list of codepoints is desirable.

* String.downcase operates on strings and there is no downcasing function that takes a single codepoint. As a consequence,
 calling String.downcase on the input word (binary) is faster than downcasing a list of codepoints in an element-wise fashion.



## Implementation

The StoutPorter2 module exports a single function, stem/1, which reduces a given word (string) to its stem.

```  
  @spec stem(String.t()) :: String.t()
  def stem(word) when is_binary(word),
    do: prelude_mark_regions(word)
```

As you can see, stem/1 is threaded directly into prelude_mark_regions/1.

Prelude_mark_regions/1 downcases the input word and then calls pre_mr/6, which performs the actual work of prelude, mark_regions and certain handling of exceptional words. In the general case, pre_mr/6 transforms the input string into a reversed list of codepoints while determining the length and regions R1, R2. Unless an exceptional word form is recognized, these four pieces of information will be passed on to step0 and from there to the remaining steps.

```
  defp prelude_mark_regions(s), 
    do: pre_mr(String.downcase(s), [], 0, false, false, [])
```

The six parameters are the (remainder of) the input string, a codepoint accumulator, a length accumulator, a flag indicating whether the string started with an apostrophe, a flag indicating whether the previous character was a vowel and finally an accumulator that will eventually contain the starting indices of R1 and R2.  

The first two clauses return the input string unmodified if it is shorter than 3 characters (not hop3):

```
  defp pre_mr(<<_c1::utf8, _c2::utf8>> = w, [], 0, false, _, _), do: w
  defp pre_mr(<<_c1::utf8>> = w, [], 0, false, _, _), do: w
```

Next, we deal with a leading apostrophe:
```
  defp pre_mr(<<cp::utf8, rest::binary>>, [], 0, false, _, []) when cp == ?',
    do: pre_mr(rest, [], 0, true, false, [])
```

Then we handle special cases for determining R1 (_arsen_ / _commun_ / _gener_):
```
  defp pre_mr("gener" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?r, ?e, ?n, ?e, ?g], 5, la_flag, false, [5])

  defp pre_mr("commun" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?n, ?u, ?m, ?m, ?o, ?c], 6, la_flag, false, [6])

  defp pre_mr("arsen" <> rest, [], 0, la_flag, _, []),
    do: pre_mr(rest, [?n, ?e, ?s, ?r, ?a], 5, la_flag, false, [5])
```


The following clauses correspond to the list of exception1 forms:
```
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
```


Upcasing of **y**s (and recording R1 / R2 if encountered):

```
  defp pre_mr(<<cp::utf8, rest::binary>>, [], 0, la_flag, _, []) when cp == ?y,
    do: pre_mr(rest, [?Y], 1, la_flag, false, [])

  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, true, r1r2) when cp == ?y do
    if length(r1r2) < 2 do
      pre_mr(rest, [?Y | acc], len + 1, la_flag, false, [len + 1 | r1r2])
    else
      pre_mr(rest, [?Y | acc], len + 1, la_flag, false, r1r2)
    end
  end
```

Carrying on counting, reversing, recording R1 / R2 (if encountered):

```
  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, true, r1r2) when length(r1r2) < 2 do
    case is_vowel(cp) do
      false -> pre_mr(rest, [cp | acc], len + 1, la_flag, false, [len + 1 | r1r2])
      true -> pre_mr(rest, [cp | acc], len + 1, la_flag, true, r1r2)
    end
  end

  defp pre_mr(<<cp::utf8, rest::binary>>, acc, len, la_flag, _, r1r2) do
    pre_mr(rest, [cp | acc], len + 1, la_flag, is_vowel(cp), r1r2)
  end
```

Input string traversal complete. If R1 and/or R2 not encountered, set to string length (meaning that the respective region is the empty string); carry on with step0:
```
  defp pre_mr(<<>>, acc, len, _la_flag, _, [r2, r1]), do: step0(acc, len, r1, r2)

  defp pre_mr(<<>>, acc, len, _la_flag, _, [r1]), do: step0(acc, len, r1, len)

  defp pre_mr(<<>>, acc, len, _la_flag, _, []), do: step0(acc, len, len, len)
```

Step0/4 matches the longest suffix and calls step1a with appropriately transformed codepoint list and length.
We are now operating in 'reverse mode', so the the suffixes (i.e. prefixes of the reversed list of codepoints) are human-readable from right to left.

```
  defp step0([?', ?s, ?' | rest], len, r1, r2), do: step1a(rest, len - 3, r1, r2)

  defp step0([?s, ?' | rest], len, r1, r2), do: step1a(rest, len - 2, r1, r2)

  defp step0([?' | rest], len, r1, r2), do: step1a(rest, len - 1, r1, r2)

  defp step0(rest, len, r1, r2), do: step1a(rest, len, r1, r2)
```

Step1a/4 is implemented analogously and threads into exception2/4, which either shortcuts to postlude/1 or carries on with step1b/4. I am omitting these definitions here and refer you to the source code. Most of the remainder of the program follows the patterns described so far.

Some clauses test whether a suffix occurs in R1 or R2.  In the example clause below, we know that the suffix is 7 characters long. It is in R1 if the length of the current word form - 7 is >= R1 as determined by prelude_mark_regions/1. (Shaving off a few more cycles by eliminating the subtraction is left as an exercise for the reader.)
```
  defp step2([?n, ?o, ?i, ?t, ?a, ?z, ?i | rest], len, r1, r2) when len - 7 >= r1,
    do: step3([?e, ?z, ?i | rest], len - 4, r1, r2)
```

All non-exceptional paths end in postlude/1, which reverses the codepoint list and turns it back into a string. The string is downcased to clean up any remaining **Y**s and is returned as the result of stem/1.
```
  defp postlude(w) do
    :lists.reverse(w)
    |> IO.iodata_to_binary()
    |> String.downcase()
  end
```

Lastly, it is worth mentioning that in Elixir, guard expressions can be defined in a reusable way via defmacro. For example,
```
  defmacrop is_vowel(cp) do
    quote do
      unquote(cp) == ?e or unquote(cp) == ?a or unquote(cp) == ?o or unquote(cp) == ?i or unquote(cp) == ?u or unquote(cp) == ?y
    end
  end
```
allows one to write (emphasis first clause):
```
  defp contains_vowel([cp | _rest]) when is_vowel(cp), do: true
  defp contains_vowel([_ | rest]), do: contains_vowel(rest)
  defp contains_vowel([]), do: false
```





## Performance / mix bench


The Porter2 web site provides a list of approximately 30k example word-stem pairs, which, when present in memory (thus avoiding IO overhead), can be processed in approximately 0.09 seconds using Erlang/OTP 21 on a 3.1 GHz i7 machine, which translates to 3 microseconds per word on average.  With ```@compile :native```, I have observed the 30k benchmark to complete in as little as 0.072 seconds.  
