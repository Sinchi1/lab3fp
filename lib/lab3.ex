defmodule Lab3 do
  # -------------------------
  # Интерполяция Гаусса
  # -------------------------
  def gauss(points, x) do
    n = length(points)
    xs = Enum.map(points, &elem(&1, 0))
    ys = Enum.map(points, &elem(&1, 1))

    # Проверка равномерности
    h = Enum.at(xs, 1) - Enum.at(xs, 0)
    unless Enum.chunk_every(xs, 2, 1, :discard)
           |> Enum.all?(fn [a,b] -> abs(b-a - h) < 1.0e-8 end) do
      raise "Gauss method requires equidistant points"
    end

    mid = div(n, 2)
    t = (x - Enum.at(xs, mid)) / h

    # Построим центральные разности
    diff_table = central_diff_table(ys)

    # Вычисляем интерполяционный многочлен
    Enum.with_index(diff_table)
    |> Enum.reduce(0.0, fn {row, i}, acc ->
      if i == 0 do
        hd(row) + acc
      else
        acc + gauss_term(t, i) * hd(row)
      end
    end)
  end


  # -------------------------
  # Функция Лагранжа
  # -------------------------
  def lagrange(points, x) do
    Enum.with_index(points)
    |> Enum.reduce(0.0, fn {{xi, yi}, i}, acc ->
      li =
        Enum.with_index(points)
        |> Enum.reduce(1.0, fn {{xj,_}, j}, prod ->
          if i != j, do: prod*(x-xj)/(xi-xj), else: prod
        end)
      acc + yi*li
    end)
  end

  # -------------------------
  # Функция Ньютона
  # -------------------------
  def newton_fun(points) do
    xs = Enum.map(points, &elem(&1,0))
    coeffs = newton_coeffs(points)

    fn x ->
      Enum.with_index(coeffs)
      |> Enum.reduce(0.0, fn {c,i}, acc ->
        mult = if i == 0 do
          1.0
        else
          0..(i-1)
          |> Enum.reduce(1.0, fn j,t -> t*(x - Enum.at(xs,j)) end)
        end
        acc + c*mult
      end)
    end
  end

  # -------------------------
  # Разделённые разности Ньютона
  # -------------------------
  defp newton_coeffs(points) do
    xs = Enum.map(points, &elem(&1,0))
    ys = Enum.map(points, &elem(&1,1))
    build_div_diff(ys, xs) |> Enum.map(&hd/1)
  end

  defp build_div_diff(cur, xs, acc \\ [])
  defp build_div_diff([y], _xs, acc), do: Enum.reverse([[y]|acc])
  defp build_div_diff(cur, xs, acc) do
    k = length(acc)
    next =
      0..(length(cur)-2)
      |> Enum.map(fn i ->
        (Enum.at(cur,i+1) - Enum.at(cur,i)) / (Enum.at(xs,i+k+1) - Enum.at(xs,i))
      end)
    build_div_diff(next, xs, [cur|acc])
  end

  # -------------------------
  # Построение таблицы центральных разностей для Гаусса
  # -------------------------
  defp central_diff_table(ys) do
    build_diff_table(ys, [])
  end

  defp build_diff_table([y], acc), do: Enum.reverse([[y]|acc])
  defp build_diff_table(cur, acc) do
    next = Enum.chunk_every(cur, 2, 1, :discard)
           |> Enum.map(fn [a,b] -> b-a end)
    build_diff_table(next, [cur|acc])
  end

  # -------------------------
  # Вычисление члена многочлена Гаусса
  # -------------------------
  defp gauss_term(t, 1), do: t
  defp gauss_term(t, n) when n > 1 do
    Enum.reduce(1..n, 1.0, fn i, acc ->
      factor = if rem(i,2)==1 do t + div(i,2) else t - div(i,2) end
      acc * factor
    end) / factorial(n)
  end

  defp factorial(0), do: 1
  defp factorial(n), do: Enum.reduce(1..n, 1, &*/2)
end

# -------------------------
# Модуль Main
# -------------------------
defmodule Main do
  def run(opts) do
    file = opts[:file] || abort("Use --file FILE")
    x = opts[:x] || abort("Use --x NUM")

    x =
      case Float.parse(x) do
        {val,_}-> val
        _-> abort("x must be float")
      end

    points = load_points(file)

    cond do
      opts[:gauss] ->
        IO.puts Lab3.gauss(points, x)

      opts[:lagrange] ->
        IO.puts Lab3.lagrange(points, x)

      opts[:newton] ->
        f = Lab3.newton_fun(points)
        IO.puts f.(x)

      true ->
        abort("Select method: --gauss / --lagrange / --newton")
    end
  end

  defp load_points(file) do
    File.stream!(file)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1==""))
    |> Enum.map(fn line ->
      [sx,sy] = String.split(line, ~r/[,; ]+/)
      {String.to_float(sx), String.to_float(sy)}
    end)
  end

  defp abort(msg) do
    IO.puts(:stderr, msg)
    System.halt(1)
  end
end

# -------------------------
# Парсинг аргументов
# -------------------------
{opts,_,_} =
  OptionParser.parse(System.argv(),
    switches: [
      file: :string,
      x: :string,
      gauss: :boolean,
      newton: :boolean,
      lagrange: :boolean
    ]
  )

Main.run(opts)
